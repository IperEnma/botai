package com.botai.chatbot.application.service;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Orquesta el flujo de mensajes según las capas activas por tenant.
 *
 * - Solo FAQ activa: con cualquier mensaje se muestra el menú (no se exigen triggers).
 * - FAQ + IA: menú cuando hay trigger/opción/FAQ; si no hay match el mensaje va a la IA. Al mostrar menú se añade hint "También puedes preguntar...".
 * - Solo IA activa: directo a Acciones (si aplica) e IA, sin evaluar menú/FAQ.
 */
public class IntentRouter {

    private static final Logger log = LoggerFactory.getLogger(IntentRouter.class);

    private final FeatureFlagService featureFlagService;
    private final FaqService faqService;
    private final HybridAiService hybridAiService;
    private final ActionDispatcher actionDispatcher;
    private final MenuService menuService;
    private final ScopeGuard scopeGuard;
    private final BotReadinessService readinessService;
    private final IntentClassifierService intentClassifierService;

    public IntentRouter(FeatureFlagService featureFlagService,
                        FaqService faqService,
                        HybridAiService hybridAiService,
                        ActionDispatcher actionDispatcher,
                        MenuService menuService,
                        ScopeGuard scopeGuard,
                        BotReadinessService readinessService,
                        IntentClassifierService intentClassifierService) {
        this.featureFlagService = featureFlagService;
        this.faqService = faqService;
        this.hybridAiService = hybridAiService;
        this.actionDispatcher = actionDispatcher;
        this.menuService = menuService;
        this.scopeGuard = scopeGuard;
        this.readinessService = readinessService;
        this.intentClassifierService = intentClassifierService;
    }

    /**
     * Route the message and produce an OutboundMessage and intent source for metrics.
     */
    public RouteResult route(InboundMessage inbound, ConversationState state) {
        String conversationId = inbound.getConversationId();
        String text = inbound.getText();
        String tenantId = getTenantId(inbound);

        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[ROUTER] tenantId ausente o vacío, respondiendo con error");
            return new RouteResult(
                OutboundMessage.builder()
                    .text("Error: no se pudo identificar el bot. Verifica la configuración del webhook (phone_number_id asociado a un bot).")
                    .conversationId(conversationId)
                    .build(),
                "error",
                null
            );
        }

        String notReady = readinessService.getNotReadyMessage(tenantId);
        if (notReady != null) {
            log.info("[ROUTER] Bot no listo: {}", notReady);
            return new RouteResult(
                OutboundMessage.builder()
                    .text(notReady)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build(),
                "bot_not_ready",
                null
            );
        }

        // Clasificador unificado: saludo, acción CRM, pregunta general, malas intenciones
        IntentClassification classification = intentClassifierService.classify(text);

        if (classification.isBadIntent()) {
            log.info("[ROUTER] Mala intención detectada -> bloqueando");
            return new RouteResult(
                OutboundMessage.builder()
                    .text("No puedo responder a eso. ¿En qué puedo ayudarte con el negocio?")
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build(),
                "bad_intent",
                null
            );
        }

        if (classification.isGreeting() && featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId) && menuService.hasAnyActiveMenu(tenantId)) {
            var firstKey = menuService.getFirstMenuKey(tenantId);
            if (firstKey.isPresent()) {
                var menuMsg = menuService.getMenu(firstKey.get(), conversationId, tenantId);
                if (menuMsg.isPresent()) {
                    log.info("[ROUTER] Saludo → mostrar primer menú");
                    return withMenuAndAiHint(menuMsg.get(), "menu", firstKey.get());
                }
            }
        }

        if (classification.isCrmAction() && featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            var actionId = classification.getActionId();
            if (actionId.isPresent()) {
                var actionResult = actionDispatcher.startFromMenuOption(state, actionId.get(), text);
                if (actionResult != null) {
                    return new RouteResult(actionResult, "action", null);
                }
            }
        }

        // 1) Menú + FAQ solo si la capa FAQ está activa (si solo está la IA, este bloque se salta y va directo a IA)
        boolean aiOn = featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
        if (featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)) {
            // Check if user is selecting a menu option (e.g., "1", "2")
            String currentMenu = state.getContextValue("currentMenu", String.class);
            if (currentMenu != null) {
                var selected = menuService.findSelectedOptionWithAction(currentMenu, text, tenantId);
                if (selected.isPresent()) {
                    var sel = selected.get();
                    if (sel.actionIntent() != null && !sel.actionIntent().isBlank() && featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
                        log.info("[ROUTER] Menu option triggers action: {} -> {}", text, sel.actionIntent());
                        var actionResult = actionDispatcher.startFromMenuOption(state, sel.actionIntent(), text);
                        if (actionResult != null) {
                            return new RouteResult(actionResult, "action", null);
                        }
                    }
                    String targetMenu = sel.targetMenuKey();
                    log.info("[ROUTER] Menu option selected: {} -> {}", text, targetMenu);
                    var menuMsg = menuService.getMenu(targetMenu, conversationId, tenantId);
                    if (menuMsg.isPresent()) {
                        return withMenuAndAiHint(menuMsg.get(), "menu", targetMenu);
                    }
                }
                
                // User is in a menu but didn't select valid option - check if it's a new trigger
                var menuTrigger = menuService.findMenuTrigger(text, tenantId);
                if (menuTrigger.isPresent()) {
                    String menuId = menuTrigger.get();
                    log.info("[ROUTER] Menu triggered while in menu: {} -> {}", text, menuId);
                    var menuMsg = menuService.getMenu(menuId, conversationId, tenantId);
                    if (menuMsg.isPresent()) {
                        return withMenuAndAiHint(menuMsg.get(), "menu", menuId);
                    }
                }
                
                // Opción no válida: si solo FAQ, mostramos menú de nuevo; si FAQ+IA dejamos pasar a IA
                if (!aiOn && menuService.hasAnyActiveMenu(tenantId)) {
                    var firstKey = menuService.getFirstMenuKey(tenantId);
                    if (firstKey.isPresent()) {
                        var menuMsg = menuService.getMenu(firstKey.get(), conversationId, tenantId);
                        if (menuMsg.isPresent()) {
                            return withMenuAndAiHint(menuMsg.get(), "menu", firstKey.get());
                        }
                    }
                }
            }

            // Check if text triggers a menu (opcional: "hola", "menu", etc.)
            var menuTrigger = menuService.findMenuTrigger(text, tenantId);
            if (menuTrigger.isPresent()) {
                String menuId = menuTrigger.get();
                log.info("[ROUTER] Menu triggered: {} -> {}", text, menuId);
                var menuMsg = menuService.getMenu(menuId, conversationId, tenantId);
                if (menuMsg.isPresent()) {
                    return withMenuAndAiHint(menuMsg.get(), "menu", menuId);
                }
            }

            // 2) Traditional FAQ keyword matching
            var faqMatch = faqService.findMatch(text);
            if (faqMatch.isPresent()) {
                var m = faqMatch.get();
                log.info("[ROUTER] FAQ match: {}", m.intent());
                return new RouteResult(
                    OutboundMessage.builder()
                        .text(m.response())
                        .conversationId(conversationId)
                        .tenantId(tenantId)
                        .build(),
                    "faq",
                    null
                );
            }

            // 3) FAQ activa con menú: con cualquier mensaje *nuevo* (sin estar ya en un menú) se muestra el primer menú
            // Si ya estábamos en menú y el usuario escribió algo que no es opción (ej. "¿qué horarios manejas?") y hay IA, no devolvemos menú aquí → va a IA
            if (menuService.hasAnyActiveMenu(tenantId) && currentMenu == null) {
                var firstMenuKey = menuService.getFirstMenuKey(tenantId);
                if (firstMenuKey.isPresent()) {
                    var menuMsg = menuService.getMenu(firstMenuKey.get(), conversationId, tenantId);
                    if (menuMsg.isPresent()) {
                        log.info("[ROUTER] FAQ: cualquier mensaje (sin menú actual) muestra primer menú");
                        return withMenuAndAiHint(menuMsg.get(), "menu", firstMenuKey.get());
                    }
                }
            }
        }

        // 3) Actions (if enabled and we have an active intent in state)
        if (featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId) && state.hasIntent()) {
            var actionResult = actionDispatcher.dispatch(state, text);
            if (actionResult != null) {
                return new RouteResult(actionResult, "action", null);
            }
        }

        // 4) IA (si está activa: directo cuando solo hay IA, o tras no hacer match en menú/FAQ/acción cuando hay ambas)
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            ScopeGuard.ScopeResult scopeResult = scopeGuard.check(text, tenantId);
            if (!scopeResult.allowed()) {
                log.info("[ROUTER] Mensaje fuera de alcance o jailbreak detectado -> respondiendo con mensaje fijo");
                return new RouteResult(
                    OutboundMessage.builder()
                        .text(scopeResult.blockMessage())
                        .conversationId(conversationId)
                        .tenantId(tenantId)
                        .build(),
                    "ai_blocked",
                    null
                );
            }
            log.info("[ROUTER] Routing to AI (Capa 2)");
            var aiResponse = hybridAiService.generateResponse(inbound, state);
            return new RouteResult(aiResponse, "ai", null);
        }

        // Sin match: mensaje final (solo FAQ ya mostró menú en el bloque anterior).
        return new RouteResult(
            OutboundMessage.builder()
                .text("No tengo una respuesta para eso. Revisa que menú, servicios, horario y conocimiento estén configurados en el panel.")
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "no_match",
            null
        );
    }

    /**
     * Extrae el tenant ID del mensaje entrante (metadata). Si no viene, retorna null.
     */
    private String getTenantId(InboundMessage inbound) {
        Object tenant = inbound.getMetadata() != null ? inbound.getMetadata().get("tenantId") : null;
        if (tenant == null) return null;
        String s = tenant.toString().strip();
        return s.isEmpty() ? null : s;
    }

    /**
     * Si la IA está activa, añade debajo del texto del menú (definido por el usuario en BD) la aclaración
     * de que puede preguntar libremente. El hint va siempre después del contenido del menú.
     */
    private RouteResult withMenuAndAiHint(OutboundMessage menuMessage, String intentSource, String newMenuId) {
        if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, getTenantIdFromMessage(menuMessage))) {
            return new RouteResult(menuMessage, intentSource, newMenuId);
        }
        String hint = "💬 También puedes escribir tu pregunta y te responderé.";
        OutboundMessage withHint = OutboundMessage.builder()
            .text(menuMessage.getText())
            .options(menuMessage.getOptions())
            .footerText(hint)
            .conversationId(menuMessage.getConversationId())
            .tenantId(menuMessage.getTenantId())
            .build();
        return new RouteResult(withHint, intentSource, newMenuId);
    }

    private String getTenantIdFromMessage(OutboundMessage msg) {
        return msg.getTenantId() != null ? msg.getTenantId() : "";
    }

    public record RouteResult(OutboundMessage message, String intentSource, String newMenuId) {}
}

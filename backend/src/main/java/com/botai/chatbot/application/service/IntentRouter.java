package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Orquesta el flujo de mensajes según las capas activas por tenant:
 *
 * - Solo IA activa: va directo a Acciones (si aplica) e IA. No se evalúa menú/FAQ.
 * - Solo FAQ activa: menú interactivo + FAQ por palabras clave; fallback menú o mensaje.
 * - FAQ + IA: se combinan: primero menú/FAQ (triggers estrictos, ej. "hola" o "menu" solos);
 *   si no hay match (p. ej. una pregunta), se pasa a la IA (RAG/conversación).
 */
public class IntentRouter {

    private static final Logger log = LoggerFactory.getLogger(IntentRouter.class);

    private final FeatureFlagService featureFlagService;
    private final FaqService faqService;
    private final HybridAiService hybridAiService;
    private final ActionDispatcher actionDispatcher;
    private final MenuService menuService;

    public IntentRouter(FeatureFlagService featureFlagService,
                        FaqService faqService,
                        HybridAiService hybridAiService,
                        ActionDispatcher actionDispatcher,
                        MenuService menuService) {
        this.featureFlagService = featureFlagService;
        this.faqService = faqService;
        this.hybridAiService = hybridAiService;
        this.actionDispatcher = actionDispatcher;
        this.menuService = menuService;
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

        // 1) Menú + FAQ solo si la capa FAQ está activa (si solo está la IA, este bloque se salta y va directo a IA)
        if (featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)) {
            // Check if user is selecting a menu option (e.g., "1", "2")
            String currentMenu = state.getContextValue("currentMenu", String.class);
            if (currentMenu != null) {
                var selected = menuService.findSelectedOption(currentMenu, text, tenantId);
                if (selected.isPresent()) {
                    String targetMenu = selected.get();
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
                
                // Opción no válida -> mostrar menú inicial (main) del mismo tenant
                if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
                    log.info("[ROUTER] Invalid menu option '{}' -> showing main menu", text);
                    var mainMenuMsg = menuService.getMenu("main", conversationId, tenantId);
                    if (mainMenuMsg.isPresent()) {
                        return withMenuAndAiHint(mainMenuMsg.get(), "menu", "main");
                    }
                }
            }

            // Check if text triggers a menu (e.g., "hola" -> main menu)
            var menuTrigger = menuService.findMenuTrigger(text, tenantId);
            if (menuTrigger.isPresent()) {
                String menuId = menuTrigger.get();
                log.info("[ROUTER] Menu triggered: {} -> {}", text, menuId);
                var menuMsg = menuService.getMenu(menuId, conversationId, tenantId);
                if (menuMsg.isPresent()) {
                    return withMenuAndAiHint(menuMsg.get(), "menu", menuId);
                }
            }

            // 2) Traditional FAQ keyword matching (fallback within FAQ layer)
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
        }

        // 3) Actions (if enabled and we have an active intent in state)
        if (featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId) && state.hasIntent()) {
            var actionResult = actionDispatcher.dispatch(state, text);
            if (actionResult != null) {
                return new RouteResult(actionResult, "action", null);
            }
        }

        // 4) Try to trigger an action by keyword (e.g. "crear lead")
        if (featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            var actionResult = actionDispatcher.tryDispatchByIntent(inbound, state);
            if (actionResult != null) {
                return new RouteResult(actionResult, "action", null);
            }
        }

        // 5) IA (si está activa: directo cuando solo hay IA, o tras no hacer match en menú/FAQ cuando hay ambas)
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            log.info("[ROUTER] Routing to AI (Capa 2)");
            var aiResponse = hybridAiService.generateResponse(inbound, state);
            return new RouteResult(aiResponse, "ai", null);
        }

        // 6) Fallback - cuando no es opción válida, mostrar menú inicial si el tenant tiene menú "main"
        var mainMenu = menuService.getMenu("main", conversationId, tenantId);
        if (mainMenu.isPresent()) {
            log.info("[ROUTER] Fallback -> showing main menu");
            return new RouteResult(mainMenu.get(), "menu", "main");
        }

        return new RouteResult(
            OutboundMessage.builder()
                .text("Escribe 'menu' para ver las opciones disponibles, o reformula tu consulta.")
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "fallback",
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

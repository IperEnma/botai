package com.botai.chatbot.application.service;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.infrastructure.config.BotMessages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Optional;

/**
 * Orquesta el flujo de mensajes según las capas activas por tenant.
 * Cada responsabilidad de enrutado está en un método que devuelve Optional.empty() si no aplica.
 *
 * - Solo FAQ activa: con cualquier mensaje se muestra el menú.
 * - FAQ + IA: menú cuando hay trigger/opción/FAQ; si no hay match el mensaje va a la IA.
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
    private final BotMessages messages;

    public IntentRouter(FeatureFlagService featureFlagService,
                        FaqService faqService,
                        HybridAiService hybridAiService,
                        ActionDispatcher actionDispatcher,
                        MenuService menuService,
                        ScopeGuard scopeGuard,
                        BotReadinessService readinessService,
                        IntentClassifierService intentClassifierService,
                        BotMessages messages) {
        this.featureFlagService = featureFlagService;
        this.faqService = faqService;
        this.hybridAiService = hybridAiService;
        this.actionDispatcher = actionDispatcher;
        this.menuService = menuService;
        this.scopeGuard = scopeGuard;
        this.readinessService = readinessService;
        this.intentClassifierService = intentClassifierService;
        this.messages = messages;
    }

    /**
     * Enruta el mensaje y produce un OutboundMessage e intent source para métricas.
     */
    public RouteResult route(InboundMessage inbound, ConversationState state) {
        String conversationId = inbound.getConversationId();
        String text = inbound.getText();
        String tenantId = getTenantId(inbound);

        return tryRouteWhenTenantMissing(conversationId, tenantId)
            .or(() -> tryRouteWhenBotNotReady(conversationId, tenantId))
            .or(() -> routeAfterClassification(conversationId, tenantId, text, inbound, state))
            .orElseGet(() -> routeNoMatch(conversationId, tenantId));
    }

    private Optional<RouteResult> routeAfterClassification(String conversationId, String tenantId, String text,
                                                          InboundMessage inbound, ConversationState state) {
        IntentClassification classification = intentClassifierService.classify(text, tenantId);
        return tryRouteClassifierError(conversationId, tenantId, classification)
            .or(() -> tryRouteBadIntent(conversationId, tenantId, classification))
            .or(() -> tryRouteGreetingWithMenu(conversationId, tenantId, text, state, classification))
            .or(() -> tryRouteCrmAction(tenantId, text, state, classification))
            .or(() -> tryRouteCrmActionWhenDisabled(conversationId, tenantId, classification))
            .or(() -> tryRouteMenuAndFaq(conversationId, tenantId, text, state))
            .or(() -> tryRouteActions(conversationId, tenantId, text, state))
            .or(() -> tryRouteToAi(conversationId, tenantId, text, inbound, state, classification))
            .or(() -> Optional.of(routeNoMatch(conversationId, tenantId)));
    }

    private Optional<RouteResult> tryRouteWhenTenantMissing(String conversationId, String tenantId) {
        if (tenantId != null && !tenantId.isBlank()) {
            return Optional.empty();
        }
        log.warn("[ROUTER] tenantId ausente o vacío, respondiendo con error");
        return Optional.of(new RouteResult(
            OutboundMessage.builder()
                .text("Error: no se pudo identificar el bot. Verifica la configuración del webhook (phone_number_id asociado a un bot).")
                .conversationId(conversationId)
                .build(),
            "error",
            null
        ));
    }

    private Optional<RouteResult> tryRouteWhenBotNotReady(String conversationId, String tenantId) {
        String notReady = readinessService.getNotReadyMessage(tenantId);
        if (notReady == null) {
            return Optional.empty();
        }
        log.info("[ROUTER] Bot no listo: {}", notReady);
        return Optional.of(new RouteResult(
            OutboundMessage.builder()
                .text(notReady)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "bot_not_ready",
            null
        ));
    }

    private Optional<RouteResult> tryRouteClassifierError(String conversationId, String tenantId, IntentClassification classification) {
        if (!classification.isServiceError()) {
            return Optional.empty();
        }
        log.warn("[ROUTER] Clasificador en error; respondiendo mensaje único al cliente");
        return Optional.of(new RouteResult(
            OutboundMessage.builder()
                .text("Algo no ha ido bien. Por favor, inténtalo en un momento.")
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "classifier_error",
            null
        ));
    }

    private Optional<RouteResult> tryRouteBadIntent(String conversationId, String tenantId, IntentClassification classification) {
        if (!classification.isBadIntent()) {
            return Optional.empty();
        }
        log.info("[ROUTER] Mala intención detectada -> bloqueando");
        return Optional.of(new RouteResult(
            OutboundMessage.builder()
                .text(messages.getBadIntent())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "bad_intent",
            null
        ));
    }

    private Optional<RouteResult> tryRouteGreetingWithMenu(String conversationId, String tenantId, String text,
                                                            ConversationState state, IntentClassification classification) {
        if (!classification.isGreeting()
            || !featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)
            || !menuService.hasAnyActiveMenu(tenantId)) {
            return Optional.empty();
        }
        return menuService.getFirstMenuKey(tenantId)
            .flatMap(firstKey -> menuService.getMenu(firstKey, conversationId, tenantId)
                .map(menuMsg -> {
                    log.info("[ROUTER] Saludo → mostrar primer menú");
                    return withMenuAndAiHint(menuMsg, "menu", firstKey);
                }));
    }

    /** Agendar lo maneja la IA con tools (RAG + getSlotsDisponibles/agendarCita). Solo view_appointments/create_lead usan acción. */
    private Optional<RouteResult> tryRouteCrmAction(String tenantId, String text, ConversationState state,
                                                    IntentClassification classification) {
        if (!classification.isCrmAction() || !featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            return Optional.empty();
        }
        if ("book_appointment".equals(classification.getActionId().orElse(null))) {
            return Optional.empty();
        }
        return classification.getActionId()
            .map(actionId -> actionDispatcher.startFromMenuOption(state, actionId, text))
            .filter(r -> r != null)
            .map(r -> new RouteResult(r, "action", null));
    }

    /** Usuario pidió agendar/ver citas pero el tenant tiene acciones desactivadas → mensaje claro sin pasar por IA. */
    private Optional<RouteResult> tryRouteCrmActionWhenDisabled(String conversationId, String tenantId,
                                                              IntentClassification classification) {
        if (!classification.isCrmAction() || featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            return Optional.empty();
        }
        log.info("[ROUTER] Acción CRM detectada pero ACTIONS_ENABLED=false -> mensaje actionsDisabled");
        return Optional.of(new RouteResult(
            OutboundMessage.builder()
                .text(messages.getActionsDisabled())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "actions_disabled",
            null
        ));
    }

    private Optional<RouteResult> tryRouteMenuAndFaq(String conversationId, String tenantId, String text, ConversationState state) {
        if (!featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)) {
            return Optional.empty();
        }
        boolean aiOn = featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
        String currentMenu = state.getContextValue("currentMenu", String.class);

        // Opción de menú seleccionada (estando ya en un menú)
        if (currentMenu != null) {
            Optional<RouteResult> fromSelection = tryRouteMenuSelection(conversationId, tenantId, text, state, currentMenu);
            if (fromSelection.isPresent()) return fromSelection;

            Optional<RouteResult> fromTriggerInMenu = tryRouteMenuTrigger(conversationId, tenantId, text);
            if (fromTriggerInMenu.isPresent()) return fromTriggerInMenu;

            if (!aiOn && menuService.hasAnyActiveMenu(tenantId)) {
                Optional<RouteResult> reshow = menuService.getFirstMenuKey(tenantId)
                    .flatMap(k -> menuService.getMenu(k, conversationId, tenantId)
                        .map(m -> withMenuAndAiHint(m, "menu", k)));
                if (reshow.isPresent()) return reshow;
            }
        }

        // Trigger de menú desde fuera (ej. "hola", "menu")
        Optional<RouteResult> fromTrigger = tryRouteMenuTrigger(conversationId, tenantId, text);
        if (fromTrigger.isPresent()) return fromTrigger;

        // FAQ por keywords
        Optional<RouteResult> fromFaq = faqService.findMatch(text)
            .map(m -> {
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
            });
        if (fromFaq.isPresent()) return fromFaq;

        // Sin menú actual: mostrar primer menú
        if (menuService.hasAnyActiveMenu(tenantId) && currentMenu == null) {
            return menuService.getFirstMenuKey(tenantId)
                .flatMap(k -> menuService.getMenu(k, conversationId, tenantId)
                    .map(m -> {
                        log.info("[ROUTER] FAQ: cualquier mensaje (sin menú actual) muestra primer menú");
                        return withMenuAndAiHint(m, "menu", k);
                    }));
        }

        return Optional.empty();
    }

    private Optional<RouteResult> tryRouteMenuSelection(String conversationId, String tenantId, String text,
                                                         ConversationState state, String currentMenu) {
        var selected = menuService.findSelectedOptionWithAction(currentMenu, text, tenantId);
        if (selected.isEmpty()) return Optional.empty();

        var sel = selected.get();
        if (sel.actionIntent() != null && !sel.actionIntent().isBlank()
            && featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            var actionResult = actionDispatcher.startFromMenuOption(state, sel.actionIntent(), text);
            if (actionResult != null) {
                log.info("[ROUTER] Menu option triggers action: {} -> {}", text, sel.actionIntent());
                return Optional.of(new RouteResult(actionResult, "action", null));
            }
        }
        String targetMenu = sel.targetMenuKey();
        log.info("[ROUTER] Menu option selected: {} -> {}", text, targetMenu);
        return menuService.getMenu(targetMenu, conversationId, tenantId)
            .map(m -> withMenuAndAiHint(m, "menu", targetMenu));
    }

    private Optional<RouteResult> tryRouteMenuTrigger(String conversationId, String tenantId, String text) {
        return menuService.findMenuTrigger(text, tenantId)
            .flatMap(menuId -> {
                log.info("[ROUTER] Menu triggered: {} -> {}", text, menuId);
                return menuService.getMenu(menuId, conversationId, tenantId)
                    .map(m -> withMenuAndAiHint(m, "menu", menuId));
            });
    }

    /** Con solo IA activa no se usa el dispatcher determinista: lo maneja el modelo (RAG/tools). Con FAQ sin IA sí se despacha a acciones. */
    private Optional<RouteResult> tryRouteActions(String conversationId, String tenantId, String text, ConversationState state) {
        if (!featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId) || !state.hasIntent()) {
            return Optional.empty();
        }
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            return Optional.empty();
        }
        return Optional.ofNullable(actionDispatcher.dispatch(state, text))
            .map(r -> new RouteResult(r, "action", null));
    }

    private Optional<RouteResult> tryRouteToAi(String conversationId, String tenantId, String text,
                                               InboundMessage inbound, ConversationState state,
                                               IntentClassification classification) {
        if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            return Optional.empty();
        }
        ScopeGuard.ScopeResult scopeResult = scopeGuard.check(text, tenantId);
        if (!scopeResult.allowed()) {
            log.info("[ROUTER] Mensaje fuera de alcance o jailbreak detectado -> respondiendo con mensaje fijo");
            String blockMsg = scopeResult.blockMessage();
            if (blockMsg == null || blockMsg.isBlank()) blockMsg = messages.getGuardrailBlock();
            return Optional.of(new RouteResult(
                OutboundMessage.builder()
                    .text(blockMsg)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build(),
                "ai_blocked",
                null
            ));
        }
        log.info("[ROUTER] Routing to AI (llamado final, con clasificación)");
        OutboundMessage aiResponse = hybridAiService.generateResponse(inbound, state, classification);
        return Optional.of(new RouteResult(aiResponse, "ai", null));
    }

    private RouteResult routeNoMatch(String conversationId, String tenantId) {
        return new RouteResult(
            OutboundMessage.builder()
                .text(messages.getNoMatch())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            "no_match",
            null
        );
    }

    private String getTenantId(InboundMessage inbound) {
        Object tenant = inbound.getMetadata() != null ? inbound.getMetadata().get("tenantId") : null;
        if (tenant == null) return null;
        String s = tenant.toString().strip();
        return s.isEmpty() ? null : s;
    }

    private RouteResult withMenuAndAiHint(OutboundMessage menuMessage, String intentSource, String newMenuId) {
        if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, menuMessage.getTenantId() != null ? menuMessage.getTenantId() : "")) {
            return new RouteResult(menuMessage, intentSource, newMenuId);
        }
        OutboundMessage withHint = OutboundMessage.builder()
            .text(menuMessage.getText())
            .options(menuMessage.getOptions())
            .footerText(messages.getAiHint())
            .conversationId(menuMessage.getConversationId())
            .tenantId(menuMessage.getTenantId())
            .build();
        return new RouteResult(withHint, intentSource, newMenuId);
    }

    public record RouteResult(OutboundMessage message, String intentSource, String newMenuId) {}
}

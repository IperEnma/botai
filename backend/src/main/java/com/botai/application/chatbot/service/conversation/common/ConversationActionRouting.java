package com.botai.application.chatbot.service.conversation.common;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.dto.IntentClassification;
import com.botai.application.chatbot.orchestration.ConversationHandlingContext;
import com.botai.application.chatbot.service.action.GetAgendaPublicUrlAction;
import com.botai.application.chatbot.service.inbound.ActionDispatcher;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Enrutado <strong>común</strong> a los tres modos: seguir una acción CRM ya iniciada y arrancar/responder ante
 * intención CRM según {@link BotFeatures#ACTIONS_ENABLED}. No incluye clasificación, saludo ni IA.
 */
@Service
public class ConversationActionRouting {

    private static final Logger log = LoggerFactory.getLogger(ConversationActionRouting.class);

    /**
     * Id legacy en menús/BD; el dispatcher lo traduce a {@link com.botai.application.chatbot.service.action.GetAgendaPublicUrlAction}.
     */
    public static final String BOOK_APPOINTMENT_ACTION_ID = "book_appointment";

    private final FeatureFlagService featureFlagService;
    private final ActionDispatcher actionDispatcher;
    private final StandardRouteResponses standardRouteResponses;

    public ConversationActionRouting(FeatureFlagService featureFlagService,
                                     ActionDispatcher actionDispatcher,
                                     StandardRouteResponses standardRouteResponses) {
        this.featureFlagService = featureFlagService;
        this.actionDispatcher = actionDispatcher;
        this.standardRouteResponses = standardRouteResponses;
    }

    /** Si hay intent activo y acciones habilitadas, delega el input al paso actual de la acción. */
    public Optional<ConversationRouteResult> continueActiveActionIfAny(ConversationHandlingContext ctx) {
        ConversationState state = ctx.state();
        String tenantId = ctx.tenantId();
        if (!featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId) || !state.hasIntent()) {
            return Optional.empty();
        }
        return Optional.ofNullable(actionDispatcher.dispatch(state, ctx.text()))
            .map(r -> new ConversationRouteResult(r, ConversationIntentSource.ACTION, null));
    }

    /**
     * Atajo global: «quiero agendar» → enlace público real (sin pasar por LLM).
     * Se invoca desde el orquestador antes de FAQ/IA.
     */
    public Optional<ConversationRouteResult> routeBookingPublicUrlFirst(ConversationHandlingContext ctx) {
        if (!InboundTextHeuristics.looksLikeNewBookingRequest(ctx.text())) {
            return Optional.empty();
        }
        if (!featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, ctx.tenantId())) {
            return Optional.empty();
        }
        if (ctx.classification().isCrmAction()
            && ctx.classification().getActionId()
                .filter(GetAgendaPublicUrlAction.ACTION_ID::equals)
                .isPresent()) {
            return startCrmFromClassificationIfEnabled(ctx);
        }
        log.info("[CRM-BOOKING] Atajo heuristica reserva -> get_agenda_public_url tenant={}", ctx.tenantId());
        var forcedCtx = new ConversationHandlingContext(
            ctx.conversationId(),
            ctx.tenantId(),
            ctx.text(),
            ctx.inbound(),
            ctx.state(),
            new IntentClassification.CrmAction(GetAgendaPublicUrlAction.ACTION_ID));
        return startCrmFromClassificationIfEnabled(forcedCtx);
    }

    /** Clasificación CRM + acciones activas → inicia la acción desde menú/clasificador. */
    public Optional<ConversationRouteResult> startCrmFromClassificationIfEnabled(ConversationHandlingContext ctx) {
        if (!ctx.classification().isCrmAction() || !featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, ctx.tenantId())) {
            return Optional.empty();
        }
        Optional<String> actionIdOpt = ctx.classification().getActionId();
        if (actionIdOpt.isEmpty()) {
            return Optional.empty();
        }
        String actionId = actionIdOpt.get();
        OutboundMessage started = actionDispatcher.startFromMenuOption(ctx.state(), actionId, ctx.text());
        if (started == null) {
            log.warn("[CRM-ACTION] No se pudo iniciar action={} tenant={}", actionId, ctx.tenantId());
            return Optional.empty();
        }
        log.info("[CRM-ACTION] OK action={} tenant={}", actionId, ctx.tenantId());
        return Optional.of(new ConversationRouteResult(started, ConversationIntentSource.ACTION, null));
    }

    /** Intención CRM pero acciones deshabilitadas para el tenant. */
    public Optional<ConversationRouteResult> respondIfCrmIntentButActionsDisabled(ConversationHandlingContext ctx) {
        if (!ctx.classification().isCrmAction() || featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, ctx.tenantId())) {
            return Optional.empty();
        }
        log.info("[CRM-ACTION] Intención CRM pero ACTIONS_ENABLED=false");
        return Optional.of(standardRouteResponses.actionsDisabled(ctx.conversationId(), ctx.tenantId()));
    }
}

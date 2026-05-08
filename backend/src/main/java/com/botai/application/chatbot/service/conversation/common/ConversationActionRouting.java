package com.botai.application.chatbot.service.conversation.common;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.orchestration.ConversationHandlingContext;
import com.botai.application.chatbot.service.inbound.ActionDispatcher;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
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

    /** Mismo id que {@link com.botai.application.chatbot.service.action.BookAppointmentAction}. */
    public static final String BOOK_APPOINTMENT_ACTION_ID = "book_appointment";

    private final FeatureFlagService featureFlagService;
    private final ActionDispatcher actionDispatcher;
    private final StandardRouteResponses standardRouteResponses;
    private final ConversationRepository conversationRepository;

    public ConversationActionRouting(FeatureFlagService featureFlagService,
                                     ActionDispatcher actionDispatcher,
                                     StandardRouteResponses standardRouteResponses,
                                     ConversationRepository conversationRepository) {
        this.featureFlagService = featureFlagService;
        this.actionDispatcher = actionDispatcher;
        this.standardRouteResponses = standardRouteResponses;
        this.conversationRepository = conversationRepository;
    }

    /** Si hay intent activo y acciones habilitadas, delega el input al paso actual de la acción. */
    public Optional<ConversationRouteResult> continueActiveActionIfAny(ConversationHandlingContext ctx) {
        ConversationState state = ctx.state();
        String tenantId = ctx.tenantId();
        if (!featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId) || !state.hasIntent()) {
            return Optional.empty();
        }
        if (BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent())
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            log.info("[CRM-ACTION] {} + IA activa -> flujo conversacional (LLM/tools), sin wizard", BOOK_APPOINTMENT_ACTION_ID);
            return Optional.empty();
        }
        return Optional.ofNullable(actionDispatcher.dispatch(state, ctx.text()))
            .map(r -> new ConversationRouteResult(r, ConversationIntentSource.ACTION, null));
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
        if (BOOK_APPOINTMENT_ACTION_ID.equals(actionId)
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, ctx.tenantId())) {
            persistBookAppointmentIntent(ctx.state());
            log.info("[CRM-ACTION] Inicio {} + IA: solo se marca intent; responde el LLM con tools", BOOK_APPOINTMENT_ACTION_ID);
            return Optional.empty();
        }
        OutboundMessage started = actionDispatcher.startFromMenuOption(ctx.state(), actionId, ctx.text());
        if (started == null) {
            return Optional.empty();
        }
        return Optional.of(new ConversationRouteResult(started, ConversationIntentSource.ACTION, null));
    }

    /**
     * Menú (u otro flujo) con opción book_appointment: si IA está activa, solo persiste el intent
     * para que responda el LLM con tools (sin wizard). Acciones deben estar habilitadas (quien llama ya lo comprobó).
     */
    public boolean armBookAppointmentForFluidAiIfApplicable(ConversationState state, String tenantId) {
        if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            return false;
        }
        persistBookAppointmentIntent(state);
        log.info("[CRM-ACTION] Intent {} armado para conversación fluida (menú u otro atajo)", BOOK_APPOINTMENT_ACTION_ID);
        return true;
    }

    private void persistBookAppointmentIntent(ConversationState state) {
        ConversationState armed = ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(BOOK_APPOINTMENT_ACTION_ID)
            .context(state.getContext())
            .build();
        conversationRepository.save(armed);
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

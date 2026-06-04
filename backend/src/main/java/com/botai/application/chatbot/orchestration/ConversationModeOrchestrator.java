package com.botai.application.chatbot.orchestration;

import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.service.conversation.common.ConversationActionRouting;
import com.botai.application.chatbot.service.inbound.BotReadinessService;
import com.botai.application.chatbot.service.inbound.IntentClassifierService;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Orquestador mínimo: precondiciones (tenant, readiness), clasificación, construcción de
 * {@link ConversationHandlingContext} y despacho al {@link ConversationModeHandler} del tenant.
 * Cada {@link ConversationModeHandler} implementa el pipeline completo de su modo (FAQ, IA o FAQ+IA).
 */
@Service
public class ConversationModeOrchestrator {

    private static final Logger log = LoggerFactory.getLogger(ConversationModeOrchestrator.class);

    private final ConversationModeResolver modeResolver;
    private final Map<ConversationMode, ConversationModeHandler> handlersByMode;
    private final BotReadinessService readinessService;
    private final IntentClassifierService intentClassifierService;
    private final ConversationActionRouting actionRouting;
    private final StandardRouteResponses standardRouteResponses;

    public ConversationModeOrchestrator(ConversationModeResolver modeResolver,
                                        List<ConversationModeHandler> handlers,
                                        BotReadinessService readinessService,
                                        IntentClassifierService intentClassifierService,
                                        ConversationActionRouting actionRouting,
                                        StandardRouteResponses standardRouteResponses) {
        this.modeResolver = modeResolver;
        this.handlersByMode = new EnumMap<>(ConversationMode.class);
        for (ConversationModeHandler handler : handlers) {
            ConversationMode m = handler.mode();
            if (handlersByMode.put(m, handler) != null) {
                throw new IllegalStateException("Duplicate ConversationModeHandler for mode: " + m);
            }
        }
        this.readinessService = readinessService;
        this.intentClassifierService = intentClassifierService;
        this.actionRouting = actionRouting;
        this.standardRouteResponses = standardRouteResponses;
    }

    @PostConstruct
    void requireHandlersForActiveModes() {
        for (ConversationMode m : List.of(ConversationMode.FAQ_ONLY, ConversationMode.AI_ONLY, ConversationMode.FAQ_AND_AI)) {
            if (!handlersByMode.containsKey(m)) {
                throw new IllegalStateException(
                    "Falta un bean ConversationModeHandler para " + m
                        + " (debe existir un @Service que implemente la interfaz: FaqConversationService, RagLlmChatService, FaqAndAiConversationService).");
            }
        }
    }

    /**
     * Punto de entrada desde {@code ConversationCore}.
     */
    public ConversationRouteResult route(InboundMessage inbound, ConversationState state) {
        String conversationId = inbound.getConversationId();
        String tenantId = InboundMetadata.tenantId(inbound);

        return whenTenantMissing(conversationId, tenantId)
            .or(() -> whenBotNotReady(conversationId, tenantId))
            .or(() -> dispatchAfterClassification(inbound, state))
            .orElseGet(() -> standardRouteResponses.noMatch(conversationId, tenantId));
    }

    private Optional<ConversationRouteResult> dispatchAfterClassification(InboundMessage inbound, ConversationState state) {
        String conversationId = inbound.getConversationId();
        String text = inbound.getText();
        String tenantId = InboundMetadata.tenantId(inbound);
        var classification = intentClassifierService.classify(text, tenantId, state);
        var ctx = new ConversationHandlingContext(conversationId, tenantId, text, inbound, state, classification);

        Optional<ConversationRouteResult> bookingShortcut = actionRouting.routeBookingPublicUrlFirst(ctx);
        if (bookingShortcut.isPresent()) {
            log.info("[ORCH] Reserva nueva -> enlace publico (sin LLM) tenant={}", tenantId);
            return bookingShortcut;
        }

        Optional<ConversationRouteResult> viewBookingsShortcut = actionRouting.routeViewAgendaBookingsFirst(ctx);
        if (viewBookingsShortcut.isPresent()) {
            log.info("[ORCH] Consulta mis citas -> view_agenda_bookings_by_contact (sin LLM) tenant={}", tenantId);
            return viewBookingsShortcut;
        }

        ConversationMode mode = modeResolver.resolve(tenantId);
        if (mode == ConversationMode.NONE) {
            log.debug("[ORCH] Modo NONE tenant={}", tenantId);
            return Optional.empty();
        }
        ConversationModeHandler handler = handlersByMode.get(mode);
        if (handler == null) {
            log.warn("[ORCH] Sin handler para modo {} — configuración incompleta", mode);
            return Optional.empty();
        }
        log.debug("[ORCH] Modo={} -> handler={}", mode, handler.getClass().getSimpleName());
        return handler.handle(ctx);
    }

    private Optional<ConversationRouteResult> whenTenantMissing(String conversationId, String tenantId) {
        if (tenantId != null && !tenantId.isBlank()) {
            return Optional.empty();
        }
        log.warn("[ORCH] tenantId ausente o vacío");
        return Optional.of(standardRouteResponses.tenantNotIdentified(conversationId));
    }

    private Optional<ConversationRouteResult> whenBotNotReady(String conversationId, String tenantId) {
        String notReady = readinessService.getNotReadyMessage(tenantId);
        if (notReady == null) {
            return Optional.empty();
        }
        log.info("[ORCH] Bot no listo: {}", notReady);
        return Optional.of(standardRouteResponses.botNotReady(conversationId, tenantId, notReady));
    }
}

package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.dto.ProcessMessageResult;
import com.botai.application.chatbot.orchestration.ConversationModeOrchestrator;
import com.botai.application.chatbot.service.feedback.ConversationFeedbackFlowService;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.infrastructure.chatbot.booking.BookingContextSanitizer;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Main entry point for processing messages. Orchestrates repository, {@link ConversationModeOrchestrator}, state, and history.
 */
public class ConversationCore {

    private static final Logger log = LoggerFactory.getLogger(ConversationCore.class);

    private final ConversationRepository conversationRepository;
    private final ConversationModeOrchestrator conversationOrchestrator;
    private final MessageHistoryService messageHistoryService;
    private final ChatSessionService chatSessionService;
    private final ConversationFeedbackFlowService conversationFeedbackFlowService;

    public ConversationCore(ConversationRepository conversationRepository,
                           ConversationModeOrchestrator conversationOrchestrator,
                           MessageHistoryService messageHistoryService,
                           ChatSessionService chatSessionService,
                           ConversationFeedbackFlowService conversationFeedbackFlowService) {
        this.conversationRepository = conversationRepository;
        this.conversationOrchestrator = conversationOrchestrator;
        this.messageHistoryService = messageHistoryService;
        this.chatSessionService = chatSessionService;
        this.conversationFeedbackFlowService = conversationFeedbackFlowService;
    }

    public ProcessMessageResult process(InboundMessage inbound) {
        String conversationId = inbound.getConversationId();
        log.info("[CORE] Processing message for conversationId={}", conversationId);
        
        final String tenantId = InboundMetadata.tenantId(inbound);
        Map<String, Object> initialContext = new java.util.HashMap<>();
        if (tenantId != null && !tenantId.isBlank()) {
            initialContext.put(InboundMetadata.TENANT_ID, tenantId);
        }

        ConversationState state = conversationRepository
            .findByConversationId(conversationId)
            .orElseGet(() -> {
                log.info("[CORE] No state found, creating new for {} (tenant={})", conversationId, tenantId);
                return ConversationState.builder()
                    .conversationId(conversationId)
                    .userId(inbound.getUserId())
                    .channelId(inbound.getChannelId())
                    .currentIntent(null)
                    .context(initialContext)
                    .build();
            });
        state = mergeInboundUserIdIntoState(state, inbound);
        state = sanitizeGarbageBookingFieldsInContext(state);
        if (state.getContext().get(InboundMetadata.TENANT_ID) == null) {
            Map<String, Object> mergedContext = new java.util.HashMap<>(state.getContext());
            mergedContext.put(InboundMetadata.TENANT_ID, tenantId);
            state = ConversationState.builder()
                .conversationId(state.getConversationId())
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(state.getCurrentIntent())
                .context(mergedContext)
                .updatedAt(state.getUpdatedAt())
                .build();
        }

        state = chatSessionService.touchSession(state, inbound.getText());
        
        log.info("[CORE] State loaded: currentMenu={}, sessionId={}, context={}", 
            state.getContextValue(ConversationContextKeys.CURRENT_MENU, String.class),
            ChatSessionService.sessionIdFrom(state),
            state.getContext());

        Optional<ConversationRouteResult> feedbackResult =
            conversationFeedbackFlowService.tryHandlePendingResponse(inbound, state);
        if (feedbackResult.isPresent()) {
            ConversationRouteResult result = feedbackResult.get();
            OutboundMessage outMessage = result.message();
            String sessionId = ChatSessionService.sessionIdFrom(state);
            saveToHistory(conversationId, sessionId, inbound.getText(),
                outMessage.getText() != null ? outMessage.getText() : "", result.intentSource());
            return new ProcessMessageResult(outMessage, result.intentSource(), conversationId);
        }

        ConversationRouteResult result = conversationOrchestrator.route(inbound, state);
        OutboundMessage outMessage = result != null ? result.message() : null;
        String intentSource = result != null ? result.intentSource() : null;

        if (outMessage != null && result != null) {
            ConversationFeedbackFlowService.FeedbackPromptOutcome prompted =
                conversationFeedbackFlowService.maybeAppendEndOfConversationPrompt(
                    inbound.getText(), outMessage, state, intentSource);
            outMessage = prompted.message();
            state = prompted.state();

            String assistantText = outMessage.getText();
            String sessionId = ChatSessionService.sessionIdFrom(state);
            saveToHistory(conversationId, sessionId, inbound.getText(), assistantText != null ? assistantText : "", intentSource);
            updateStateWithMenu(state, result, inbound);
        }

        return new ProcessMessageResult(
            outMessage,
            intentSource != null ? intentSource : ConversationIntentSource.ERROR,
            conversationId
        );
    }

    private void saveToHistory(String conversationId, String sessionId, String userText, String assistantText, String source) {
        if (!ConversationIntentSource.historyManagedByAiLayer(source)) {
            messageHistoryService.saveUserMessage(conversationId, sessionId, userText);
            messageHistoryService.saveAssistantMessage(conversationId, sessionId, assistantText);
        }
    }

    private void updateStateWithMenu(ConversationState state, ConversationRouteResult result, InboundMessage inbound) {
        if (result.newMenuId() != null) {
            Map<String, Object> newContext = new java.util.HashMap<>(state.getContext());
            newContext.put(ConversationContextKeys.CURRENT_MENU, result.newMenuId());
            String tid = InboundMetadata.tenantId(inbound);
            if (tid != null) {
                newContext.put(InboundMetadata.TENANT_ID, tid);
            }
            log.info("[CORE] Saving state with currentMenu={} for {}", result.newMenuId(), state.getConversationId());
            ConversationState updated = ConversationState.builder()
                .conversationId(state.getConversationId())
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(state.getCurrentIntent())
                .context(newContext)
                .build();
            conversationRepository.save(mergePersistedIntentWithLocalContext(updated));
            log.info("[CORE] State saved successfully");
        } else if (!ConversationIntentSource.skipSavingStaleStateAfterRoute(result.intentSource())) {
            // Acciones ya persisten su estado (step, etc.); no sobrescribir con el state inicial
            log.info("[CORE] No menu change, saving state as-is");
            conversationRepository.save(mergePersistedIntentWithLocalContext(state));
        }
    }

    /**
     * El {@code state} en memoria se cargó al inicio del request; durante el mismo request el router puede haber
     * persistido {@code currentIntent} (p. ej. book_appointment + IA). Un {@code save(state)} directo borraría ese
     * intent en BD. Preferimos intent no vacío desde BD; el contexto local (sesión, touch) tiene prioridad.
     */
    private ConversationState mergePersistedIntentWithLocalContext(ConversationState local) {
        Optional<ConversationState> fromDb = conversationRepository.findByConversationId(local.getConversationId());
        if (fromDb.isEmpty()) {
            return local;
        }
        ConversationState db = fromDb.get();
        String intent = firstNonBlank(db.getCurrentIntent(), local.getCurrentIntent());
        return ConversationState.builder()
            .conversationId(local.getConversationId())
            .userId(local.getUserId())
            .channelId(local.getChannelId())
            .currentIntent(intent)
            .context(local.getContext())
            .updatedAt(local.getUpdatedAt())
            .build();
    }

    private static String firstNonBlank(String a, String b) {
        if (a != null && !a.isBlank()) {
            return a;
        }
        return b;
    }

    /**
     * WhatsApp y otros canales envían siempre el remitente en el inbound; el estado persistido a veces no tenía userId.
     * Las tools (cancelar por número) necesitan el id del canal alineado con {@code appointment.user_id}.
     */
    /**
     * Quita del contexto persistido nombre/cédula que son placeholders (p. ej. "Hola" guardado como documento),
     * para que el LLM no use datos falsos al cancelar o verificar.
     */
    private static ConversationState sanitizeGarbageBookingFieldsInContext(ConversationState state) {
        Map<String, Object> ctx = state.getContext();
        if (ctx == null || ctx.isEmpty()) {
            return state;
        }
        Object docObj = ctx.get(ConversationContextKeys.CUSTOMER_DOCUMENT);
        Object nameObj = ctx.get(ConversationContextKeys.CUSTOMER_NAME);
        boolean clearDoc = docObj != null
            && BookingContextSanitizer.isPlaceholderDocument(docObj.toString());
        boolean clearName = nameObj != null
            && BookingContextSanitizer.isPlaceholderName(nameObj.toString());
        if (!clearDoc && !clearName) {
            return state;
        }
        Map<String, Object> merged = new HashMap<>(ctx);
        if (clearDoc) {
            merged.remove(ConversationContextKeys.CUSTOMER_DOCUMENT);
            log.info("[CORE] Contexto: eliminado customerDocument placeholder para {}", state.getConversationId());
        }
        if (clearName) {
            merged.remove(ConversationContextKeys.CUSTOMER_NAME);
            log.info("[CORE] Contexto: eliminado customerName placeholder para {}", state.getConversationId());
        }
        return ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(state.getCurrentIntent())
            .context(merged)
            .updatedAt(state.getUpdatedAt())
            .build();
    }

    private static ConversationState mergeInboundUserIdIntoState(ConversationState state, InboundMessage inbound) {
        String fromInbound = inbound.getUserId();
        boolean inboundUsable = fromInbound != null && !fromInbound.isBlank()
            && !"unknown".equalsIgnoreCase(fromInbound.strip());
        if (!inboundUsable) {
            return state;
        }
        String current = state.getUserId();
        if (current != null && current.equals(fromInbound)) {
            return state;
        }
        return ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(fromInbound)
            .channelId(state.getChannelId())
            .currentIntent(state.getCurrentIntent())
            .context(state.getContext())
            .updatedAt(state.getUpdatedAt())
            .build();
    }
}

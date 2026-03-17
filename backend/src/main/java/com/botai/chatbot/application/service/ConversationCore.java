package com.botai.chatbot.application.service;

import com.botai.chatbot.application.dto.ProcessMessageResult;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.repository.ConversationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

/**
 * Main entry point for processing messages. Orchestrates repository, router, state, and history.
 */
public class ConversationCore {

    private static final Logger log = LoggerFactory.getLogger(ConversationCore.class);

    private final ConversationRepository conversationRepository;
    private final IntentRouter intentRouter;
    private final MessageHistoryService messageHistoryService;

    public ConversationCore(ConversationRepository conversationRepository, 
                           IntentRouter intentRouter,
                           MessageHistoryService messageHistoryService) {
        this.conversationRepository = conversationRepository;
        this.intentRouter = intentRouter;
        this.messageHistoryService = messageHistoryService;
    }

    public ProcessMessageResult process(InboundMessage inbound) {
        String conversationId = inbound.getConversationId();
        log.info("[CORE] Processing message for conversationId={}", conversationId);
        
        Object t = inbound.getMetadata() != null ? inbound.getMetadata().get("tenantId") : null;
        final String tenantId = (t != null && !t.toString().strip().isEmpty()) ? t.toString().strip() : null;
        Map<String, Object> initialContext = new java.util.HashMap<>();
        if (tenantId != null && !tenantId.isBlank()) {
            initialContext.put("tenantId", tenantId);
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
        if (state.getContext().get("tenantId") == null) {
            Map<String, Object> mergedContext = new java.util.HashMap<>(state.getContext());
            mergedContext.put("tenantId", tenantId);
            state = ConversationState.builder()
                .conversationId(state.getConversationId())
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(state.getCurrentIntent())
                .context(mergedContext)
                .updatedAt(state.getUpdatedAt())
                .build();
        }
        
        log.info("[CORE] State loaded: currentMenu={}, context={}", 
            state.getContextValue("currentMenu", String.class), state.getContext());

        IntentRouter.RouteResult result = intentRouter.route(inbound, state);
        OutboundMessage outMessage = result != null ? result.message() : null;
        String intentSource = result != null ? result.intentSource() : null;

        if (outMessage != null && result != null) {
            String assistantText = outMessage.getText();
            saveToHistory(conversationId, inbound.getText(), assistantText != null ? assistantText : "", intentSource);
            updateStateWithMenu(state, result, inbound);
        }

        return new ProcessMessageResult(
            outMessage,
            intentSource != null ? intentSource : "error",
            conversationId
        );
    }

    private void saveToHistory(String conversationId, String userText, String assistantText, String source) {
        if (!"ai".equals(source)) {
            messageHistoryService.saveUserMessage(conversationId, userText);
            messageHistoryService.saveAssistantMessage(conversationId, assistantText);
        }
    }

    private void updateStateWithMenu(ConversationState state, IntentRouter.RouteResult result, InboundMessage inbound) {
        if (result.newMenuId() != null) {
            Map<String, Object> newContext = new java.util.HashMap<>(state.getContext());
            newContext.put("currentMenu", result.newMenuId());
            if (inbound.getMetadata() != null) {
                Object tid = inbound.getMetadata().get("tenantId");
                if (tid != null) newContext.put("tenantId", tid.toString());
            }
            log.info("[CORE] Saving state with currentMenu={} for {}", result.newMenuId(), state.getConversationId());
            ConversationState updated = ConversationState.builder()
                .conversationId(state.getConversationId())
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(state.getCurrentIntent())
                .context(newContext)
                .build();
            conversationRepository.save(updated);
            log.info("[CORE] State saved successfully");
        } else if (!"action".equals(result.intentSource()) && !"actions_disabled".equals(result.intentSource())) {
            // Acciones ya persisten su estado (step, etc.); no sobrescribir con el state inicial
            log.info("[CORE] No menu change, saving state as-is");
            conversationRepository.save(state);
        }
    }
}

package com.botai.application.chatbot.dto;

import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;

import java.util.List;

/**
 * Entrada para {@link com.botai.application.chatbot.service.conversation.ai.RagLlmChatService#replyWithLlm}.
 */
public record AiConversationRequest(
    InboundMessage inbound,
    ConversationState state,
    IntentClassification classification,
    List<String> supplementalSystemLines
) {
    public static AiConversationRequest of(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        return new AiConversationRequest(inbound, state, classification, List.of());
    }
}

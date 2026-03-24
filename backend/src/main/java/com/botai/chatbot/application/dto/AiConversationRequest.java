package com.botai.chatbot.application.dto;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;

import java.util.List;

/**
 * Entrada para {@link com.botai.chatbot.application.service.conversation.ai.RagLlmChatService#replyWithLlm}.
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

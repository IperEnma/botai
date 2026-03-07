package com.botai.chatbot.domain.model;

import java.util.Collections;
import java.util.List;

/**
 * Agnostic request to a language model. No provider-specific fields.
 */
public final class LlmRequest {

    private final String userMessage;
    private final List<String> systemPromptLines;
    private final List<String> conversationHistory;
    private final int maxTokens;

    public LlmRequest(String userMessage, List<String> systemPromptLines,
                      List<String> conversationHistory, int maxTokens) {
        this.userMessage = userMessage;
        this.systemPromptLines = systemPromptLines != null ? List.copyOf(systemPromptLines) : Collections.emptyList();
        this.conversationHistory = conversationHistory != null ? List.copyOf(conversationHistory) : Collections.emptyList();
        this.maxTokens = maxTokens > 0 ? maxTokens : 512;
    }

    public String getUserMessage() {
        return userMessage;
    }

    public List<String> getSystemPromptLines() {
        return systemPromptLines;
    }

    public List<String> getConversationHistory() {
        return conversationHistory;
    }

    public int getMaxTokens() {
        return maxTokens;
    }
}

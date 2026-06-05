package com.botai.domain.chatbot.model;

public enum ConversationFeedbackRating {
    POSITIVE,
    NEGATIVE;

    public static ConversationFeedbackRating from(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("rating required");
        }
        return valueOf(raw.trim().toUpperCase());
    }
}

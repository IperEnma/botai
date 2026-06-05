package com.botai.domain.chatbot.model;

import java.time.Instant;

public final class ConversationFeedback {

    private final Long id;
    private final String tenantId;
    private final String conversationId;
    private final String sessionId;
    private final String userMessage;
    private final String botReply;
    private final ConversationFeedbackRating rating;
    private final String intentSource;
    private final boolean promotedToFaq;
    private final Instant createdAt;

    public ConversationFeedback(Long id, String tenantId, String conversationId, String sessionId,
                                String userMessage, String botReply, ConversationFeedbackRating rating,
                                String intentSource, boolean promotedToFaq, Instant createdAt) {
        this.id = id;
        this.tenantId = tenantId;
        this.conversationId = conversationId;
        this.sessionId = sessionId;
        this.userMessage = userMessage;
        this.botReply = botReply;
        this.rating = rating;
        this.intentSource = intentSource;
        this.promotedToFaq = promotedToFaq;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getConversationId() { return conversationId; }
    public String getSessionId() { return sessionId; }
    public String getUserMessage() { return userMessage; }
    public String getBotReply() { return botReply; }
    public ConversationFeedbackRating getRating() { return rating; }
    public String getIntentSource() { return intentSource; }
    public boolean isPromotedToFaq() { return promotedToFaq; }
    public Instant getCreatedAt() { return createdAt; }
}

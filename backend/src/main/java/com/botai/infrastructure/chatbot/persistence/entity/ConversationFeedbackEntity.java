package com.botai.infrastructure.chatbot.persistence.entity;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "conversation_feedback", indexes = {
    @Index(name = "idx_feedback_tenant", columnList = "tenant_id"),
    @Index(name = "idx_feedback_conversation", columnList = "conversation_id")
})
public class ConversationFeedbackEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "conversation_id", nullable = false, length = 128)
    private String conversationId;

    @Column(name = "session_id", length = 128)
    private String sessionId;

    @Column(name = "user_message", columnDefinition = "text")
    private String userMessage;

    @Column(name = "bot_reply", columnDefinition = "text")
    private String botReply;

    @Column(name = "rating", nullable = false, length = 16)
    private String rating;

    @Column(name = "intent_source", length = 32)
    private String intentSource;

    @Column(name = "promoted_to_faq", nullable = false)
    private boolean promotedToFaq = false;

    @Column(name = "created_at")
    private Instant createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }
    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }
    public String getUserMessage() { return userMessage; }
    public void setUserMessage(String userMessage) { this.userMessage = userMessage; }
    public String getBotReply() { return botReply; }
    public void setBotReply(String botReply) { this.botReply = botReply; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public String getIntentSource() { return intentSource; }
    public void setIntentSource(String intentSource) { this.intentSource = intentSource; }
    public boolean isPromotedToFaq() { return promotedToFaq; }
    public void setPromotedToFaq(boolean promotedToFaq) { this.promotedToFaq = promotedToFaq; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

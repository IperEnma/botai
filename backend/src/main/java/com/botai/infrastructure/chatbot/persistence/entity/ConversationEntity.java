package com.botai.infrastructure.chatbot.persistence.entity;

import jakarta.persistence.*;
import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "conversation")
public class ConversationEntity {

    @Id
    @Column(name = "conversation_id", length = 255)
    private String conversationId;

    @Column(name = "user_id", nullable = false, length = 255)
    private String userId;

    @Column(name = "channel_id", nullable = false, length = 64)
    private String channelId;

    @Column(name = "current_intent", length = 128)
    private String currentIntent;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "conversation_context", joinColumns = @JoinColumn(name = "conversation_id"))
    @MapKeyColumn(name = "context_key")
    @Column(name = "context_value", columnDefinition = "text")
    private Map<String, String> context = new HashMap<>();

    @Column(name = "updated_at")
    private long updatedAt;

    @PrePersist
    @PreUpdate
    public void setUpdatedAt() {
        this.updatedAt = System.currentTimeMillis();
    }

    public String getConversationId() {
        return conversationId;
    }

    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getChannelId() {
        return channelId;
    }

    public void setChannelId(String channelId) {
        this.channelId = channelId;
    }

    public String getCurrentIntent() {
        return currentIntent;
    }

    public void setCurrentIntent(String currentIntent) {
        this.currentIntent = currentIntent;
    }

    public Map<String, String> getContext() {
        return context;
    }

    public void setContext(Map<String, String> context) {
        this.context = context != null ? context : new HashMap<>();
    }

    public long getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(long updatedAt) {
        this.updatedAt = updatedAt;
    }
}

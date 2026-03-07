package com.botai.chatbot.domain.model;

import java.util.Collections;
import java.util.Map;

/**
 * Represents the conversational state for a user/session.
 * Used by actions and intent routing (e.g. waiting for lead data).
 */
public final class ConversationState {

    private final String conversationId;
    private final String userId;
    private final String channelId;
    private final String currentIntent;
    private final Map<String, Object> context;
    private final long updatedAt;

    public ConversationState(String conversationId, String userId, String channelId,
                             String currentIntent, Map<String, Object> context, long updatedAt) {
        this.conversationId = conversationId;
        this.userId = userId;
        this.channelId = channelId;
        this.currentIntent = currentIntent;
        this.context = context != null ? Map.copyOf(context) : Collections.emptyMap();
        this.updatedAt = updatedAt;
    }

    public String getConversationId() {
        return conversationId;
    }

    public String getUserId() {
        return userId;
    }

    public String getChannelId() {
        return channelId;
    }

    public String getCurrentIntent() {
        return currentIntent;
    }

    public Map<String, Object> getContext() {
        return context;
    }

    public long getUpdatedAt() {
        return updatedAt;
    }

    public boolean hasIntent() {
        return currentIntent != null && !currentIntent.isBlank();
    }

    @SuppressWarnings("unchecked")
    public <T> T getContextValue(String key, Class<T> type) {
        Object v = context.get(key);
        return type.isInstance(v) ? (T) v : null;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static final class Builder {
        private String conversationId;
        private String userId;
        private String channelId;
        private String currentIntent;
        private Map<String, Object> context = Collections.emptyMap();
        private long updatedAt = System.currentTimeMillis();

        public Builder conversationId(String conversationId) {
            this.conversationId = conversationId;
            return this;
        }

        public Builder userId(String userId) {
            this.userId = userId;
            return this;
        }

        public Builder channelId(String channelId) {
            this.channelId = channelId;
            return this;
        }

        public Builder currentIntent(String currentIntent) {
            this.currentIntent = currentIntent;
            return this;
        }

        public Builder context(Map<String, Object> context) {
            this.context = context != null ? context : Collections.emptyMap();
            return this;
        }

        public Builder updatedAt(long updatedAt) {
            this.updatedAt = updatedAt;
            return this;
        }

        public ConversationState build() {
            return new ConversationState(conversationId, userId, channelId, currentIntent, context, updatedAt);
        }
    }
}

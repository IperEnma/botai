package com.botai.chatbot.domain.model;

import java.util.Collections;
import java.util.Map;

/**
 * Canal-agnostic representation of an incoming user message.
 * The core only works with this model; channel adapters translate from external formats.
 */
public final class InboundMessage {

    private final String channelId;
    private final String userId;
    private final String conversationId;
    private final String text;
    private final Map<String, Object> metadata;

    public InboundMessage(String channelId, String userId, String conversationId, String text,
                          Map<String, Object> metadata) {
        this.channelId = channelId;
        this.userId = userId;
        this.conversationId = conversationId;
        this.text = text != null ? text.strip() : "";
        this.metadata = metadata != null ? Map.copyOf(metadata) : Collections.emptyMap();
    }

    public String getChannelId() {
        return channelId;
    }

    public String getUserId() {
        return userId;
    }

    public String getConversationId() {
        return conversationId;
    }

    public String getText() {
        return text;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static final class Builder {
        private String channelId;
        private String userId;
        private String conversationId;
        private String text;
        private Map<String, Object> metadata = Collections.emptyMap();

        public Builder channelId(String channelId) {
            this.channelId = channelId;
            return this;
        }

        public Builder userId(String userId) {
            this.userId = userId;
            return this;
        }

        public Builder conversationId(String conversationId) {
            this.conversationId = conversationId;
            return this;
        }

        public Builder text(String text) {
            this.text = text;
            return this;
        }

        public Builder metadata(Map<String, Object> metadata) {
            this.metadata = metadata != null ? metadata : Collections.emptyMap();
            return this;
        }

        public InboundMessage build() {
            return new InboundMessage(channelId, userId, conversationId, text, metadata);
        }
    }
}

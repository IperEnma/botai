package com.botai.chatbot.domain.model;

import java.util.Collections;
import java.util.List;

/**
 * Canal-agnostic representation of a message to send back to the user.
 * Channel adapters translate this to the specific channel format.
 */
public final class OutboundMessage {

    private final String text;
    private final List<String> options;
    /** Texto opcional a mostrar después de las opciones (ej. hint "También puedes escribir tu pregunta"). */
    private final String footerText;
    private final List<MessageAction> actions;
    private final String conversationId;
    private final String tenantId;

    public OutboundMessage(String text, List<String> options, String footerText, List<MessageAction> actions, String conversationId, String tenantId) {
        this.text = text != null ? text : "";
        this.options = options != null ? List.copyOf(options) : Collections.emptyList();
        this.footerText = footerText != null && !footerText.isBlank() ? footerText : null;
        this.actions = actions != null ? List.copyOf(actions) : Collections.emptyList();
        this.conversationId = conversationId;
        this.tenantId = tenantId;
    }

    public String getText() {
        return text;
    }

    public String getFooterText() {
        return footerText;
    }

    public List<String> getOptions() {
        return options;
    }

    public List<MessageAction> getActions() {
        return actions;
    }

    public String getConversationId() {
        return conversationId;
    }

    public String getTenantId() {
        return tenantId;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static final class Builder {
        private String text = "";
        private List<String> options = Collections.emptyList();
        private String footerText;
        private List<MessageAction> actions = Collections.emptyList();
        private String conversationId;
        private String tenantId;

        public Builder text(String text) {
            this.text = text;
            return this;
        }

        public Builder options(List<String> options) {
            this.options = options != null ? options : Collections.emptyList();
            return this;
        }

        public Builder footerText(String footerText) {
            this.footerText = footerText;
            return this;
        }

        public Builder actions(List<MessageAction> actions) {
            this.actions = actions != null ? actions : Collections.emptyList();
            return this;
        }

        public Builder conversationId(String conversationId) {
            this.conversationId = conversationId;
            return this;
        }

        public Builder tenantId(String tenantId) {
            this.tenantId = tenantId;
            return this;
        }

        public OutboundMessage build() {
            return new OutboundMessage(text, options, footerText, actions, conversationId, tenantId);
        }
    }

    /**
     * Represents an actionable button/quick reply in the message.
     */
    public record MessageAction(String id, String label, String type) {
        public MessageAction {
            type = type != null ? type : "button";
        }
    }
}

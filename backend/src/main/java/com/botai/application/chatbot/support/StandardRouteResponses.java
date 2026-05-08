package com.botai.application.chatbot.support;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.infrastructure.chatbot.config.BotMessages;
import org.springframework.stereotype.Component;

/**
 * Respuestas fijas del pipeline de enrutado (sin IA). Centraliza textos y {@link ConversationRouteResult}.
 */
@Component
public class StandardRouteResponses {

    private final BotMessages messages;

    public StandardRouteResponses(BotMessages messages) {
        this.messages = messages;
    }

    public ConversationRouteResult tenantNotIdentified(String conversationId) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(BotPrompts.UserFacing.TENANT_WEBHOOK_NOT_IDENTIFIED)
                .conversationId(conversationId)
                .build(),
            ConversationIntentSource.ERROR,
            null
        );
    }

    public ConversationRouteResult botNotReady(String conversationId, String tenantId, String notReadyMessage) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(notReadyMessage)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.BOT_NOT_READY,
            null
        );
    }

    public ConversationRouteResult classifierUnavailable(String conversationId, String tenantId) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(BotPrompts.UserFacing.RETRY_LATER)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.CLASSIFIER_ERROR,
            null
        );
    }

    public ConversationRouteResult badIntent(String conversationId, String tenantId) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(messages.getBadIntent())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.BAD_INTENT,
            null
        );
    }

    public ConversationRouteResult actionsDisabled(String conversationId, String tenantId) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(messages.getActionsDisabled())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.ACTIONS_DISABLED,
            null
        );
    }

    public ConversationRouteResult noMatch(String conversationId, String tenantId) {
        return new ConversationRouteResult(
            OutboundMessage.builder()
                .text(messages.getNoMatch())
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.NO_MATCH,
            null
        );
    }

}

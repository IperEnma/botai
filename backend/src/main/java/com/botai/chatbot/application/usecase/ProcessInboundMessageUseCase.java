package com.botai.chatbot.application.usecase;

import com.botai.chatbot.application.dto.ProcessMessageResult;
import com.botai.chatbot.application.service.inbound.ConversationCore;
import com.botai.chatbot.domain.model.InboundMessage;

/**
 * Use case: process an inbound message and return the result (for adapter to send).
 */
public class ProcessInboundMessageUseCase {

    private final ConversationCore conversationCore;

    public ProcessInboundMessageUseCase(ConversationCore conversationCore) {
        this.conversationCore = conversationCore;
    }

    public ProcessMessageResult execute(InboundMessage inbound) {
        return conversationCore.process(inbound);
    }
}

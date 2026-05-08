package com.botai.application.chatbot.usecase;

import com.botai.application.chatbot.dto.ProcessMessageResult;
import com.botai.application.chatbot.service.inbound.ConversationCore;
import com.botai.domain.chatbot.model.InboundMessage;

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

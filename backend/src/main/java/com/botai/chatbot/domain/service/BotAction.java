package com.botai.chatbot.domain.service;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.OutboundMessage;

/**
 * Port for bot actions (CRM, business operations). Actions do not know channel or AI.
 */
public interface BotAction {

    /**
     * Unique action identifier (e.g. "create_lead", "book_appointment").
     */
    String getActionId();

    /**
     * Optional trigger intent/keyword to start this action from user message.
     */
    default String getTriggerIntent() {
        return null;
    }

    /**
     * Execute the action. May update state via ConversationRepository.
     *
     * @param state current conversation state
     * @param userInput latest user message
     * @return response to send, or null if action did not handle (e.g. wrong step)
     */
    OutboundMessage execute(ConversationState state, String userInput);
}

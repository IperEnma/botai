package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.ConversationState;

import java.util.Optional;

/**
 * Port for persisting and retrieving conversation state.
 * Implementation lives in infrastructure.
 */
public interface ConversationRepository {

    Optional<ConversationState> findByConversationId(String conversationId);

    void save(ConversationState state);

    void clearIntent(String conversationId);
}

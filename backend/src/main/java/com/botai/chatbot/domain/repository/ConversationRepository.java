package com.botai.chatbot.domain.repository;

import com.botai.chatbot.domain.model.ConversationState;

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

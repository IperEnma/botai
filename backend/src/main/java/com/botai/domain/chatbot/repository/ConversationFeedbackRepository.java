package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.ConversationFeedback;
import com.botai.domain.chatbot.model.ConversationFeedbackRating;

import java.util.List;
import java.util.Optional;

public interface ConversationFeedbackRepository {

    ConversationFeedback save(ConversationFeedback feedback);

    List<ConversationFeedback> findByTenantIdOrderByCreatedAtDesc(String tenantId, int limit);

    Optional<ConversationFeedback> findByIdAndTenantId(long id, String tenantId);

    void markPromotedToFaq(long id, String tenantId);
}

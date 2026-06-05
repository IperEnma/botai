package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.ConversationFeedback;
import com.botai.domain.chatbot.model.ConversationFeedbackRating;
import com.botai.domain.chatbot.repository.ConversationFeedbackRepository;
import com.botai.infrastructure.chatbot.persistence.entity.ConversationFeedbackEntity;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Repository
public class JpaConversationFeedbackRepository implements ConversationFeedbackRepository {

    private final ConversationFeedbackJpaRepository jpaRepository;

    public JpaConversationFeedbackRepository(ConversationFeedbackJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public ConversationFeedback save(ConversationFeedback feedback) {
        ConversationFeedbackEntity entity = new ConversationFeedbackEntity();
        entity.setTenantId(feedback.getTenantId());
        entity.setConversationId(feedback.getConversationId());
        entity.setSessionId(feedback.getSessionId());
        entity.setUserMessage(feedback.getUserMessage());
        entity.setBotReply(feedback.getBotReply());
        entity.setRating(feedback.getRating().name());
        entity.setIntentSource(feedback.getIntentSource());
        entity.setPromotedToFaq(feedback.isPromotedToFaq());
        entity.setCreatedAt(feedback.getCreatedAt() != null ? feedback.getCreatedAt() : Instant.now());
        ConversationFeedbackEntity saved = jpaRepository.save(entity);
        return toDomain(saved);
    }

    @Override
    public List<ConversationFeedback> findByTenantIdOrderByCreatedAtDesc(String tenantId, int limit) {
        if (tenantId == null || tenantId.isBlank()) {
            return List.of();
        }
        return jpaRepository.findByTenantIdOrderByCreatedAtDesc(tenantId).stream()
            .limit(Math.max(1, limit))
            .map(this::toDomain)
            .collect(Collectors.toList());
    }

    @Override
    public Optional<ConversationFeedback> findByIdAndTenantId(long id, String tenantId) {
        return jpaRepository.findByIdAndTenantId(id, tenantId).map(this::toDomain);
    }

    @Override
    @Transactional
    public void markPromotedToFaq(long id, String tenantId) {
        jpaRepository.markPromoted(id, tenantId);
    }

    private ConversationFeedback toDomain(ConversationFeedbackEntity e) {
        return new ConversationFeedback(
            e.getId(),
            e.getTenantId(),
            e.getConversationId(),
            e.getSessionId(),
            e.getUserMessage(),
            e.getBotReply(),
            ConversationFeedbackRating.from(e.getRating()),
            e.getIntentSource(),
            e.isPromotedToFaq(),
            e.getCreatedAt()
        );
    }
}

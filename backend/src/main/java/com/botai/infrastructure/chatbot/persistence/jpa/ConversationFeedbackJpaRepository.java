package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.ConversationFeedbackEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConversationFeedbackJpaRepository extends JpaRepository<ConversationFeedbackEntity, Long> {

    List<ConversationFeedbackEntity> findByTenantIdOrderByCreatedAtDesc(String tenantId);

    Optional<ConversationFeedbackEntity> findByIdAndTenantId(Long id, String tenantId);

    @Modifying
    @Query("UPDATE ConversationFeedbackEntity f SET f.promotedToFaq = true WHERE f.id = :id AND f.tenantId = :tenantId")
    int markPromoted(@Param("id") long id, @Param("tenantId") String tenantId);
}

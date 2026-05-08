package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface KnowledgeChunkJpaRepository extends JpaRepository<KnowledgeChunkEntity, Long> {

    List<KnowledgeChunkEntity> findByActiveTrue();

    List<KnowledgeChunkEntity> findByTenantIdAndActiveTrue(String tenantId);

    long countByTenantIdAndActiveTrue(String tenantId);

    Optional<KnowledgeChunkEntity> findByTenantIdAndTopic(String tenantId, String topic);

    Optional<KnowledgeChunkEntity> findByTenantIdAndTopicAndBusinessId(String tenantId, String topic, UUID businessId);
}

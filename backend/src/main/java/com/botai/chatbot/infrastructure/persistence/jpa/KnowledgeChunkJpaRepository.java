package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.KnowledgeChunkEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface KnowledgeChunkJpaRepository extends JpaRepository<KnowledgeChunkEntity, Long> {

    List<KnowledgeChunkEntity> findByActiveTrue();
    
    List<KnowledgeChunkEntity> findByTenantIdAndActiveTrue(String tenantId);
}

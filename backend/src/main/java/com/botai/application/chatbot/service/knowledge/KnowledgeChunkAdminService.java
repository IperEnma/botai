package com.botai.application.chatbot.service.knowledge;

import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.KnowledgeChunkJpaRepository;
import com.botai.infrastructure.chatbot.rag.RagSourceSync;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Casos de uso de administración de fragmentos de conocimiento (RAG).
 * Persiste y marca el embedding para regeneración cuando cambia el contenido.
 */
@Service
public class KnowledgeChunkAdminService {

    private final KnowledgeChunkJpaRepository knowledgeRepository;
    private final RagSourceSync ragSourceSync;

    public KnowledgeChunkAdminService(KnowledgeChunkJpaRepository knowledgeRepository,
                                       RagSourceSync ragSourceSync) {
        this.knowledgeRepository = knowledgeRepository;
        this.ragSourceSync = ragSourceSync;
    }

    public List<KnowledgeChunkEntity> getByTenant(String tenantId) {
        return knowledgeRepository.findByTenantIdAndActiveTrue(tenantId);
    }

    @Transactional
    public KnowledgeChunkEntity create(String tenantId, KnowledgeChunkEntity chunk) {
        chunk.setTenantId(tenantId);
        chunk.setActive(true);
        KnowledgeChunkEntity saved = knowledgeRepository.save(chunk);
        ragSourceSync.clearEmbeddingForChunk(saved.getId());
        return saved;
    }

    @Transactional
    public Optional<KnowledgeChunkEntity> update(String tenantId, Long chunkId, KnowledgeChunkEntity chunk) {
        return knowledgeRepository.findById(chunkId)
            .filter(existing -> tenantId.equals(existing.getTenantId()))
            .map(existing -> {
                existing.setTopic(chunk.getTopic());
                existing.setContent(chunk.getContent());
                existing.setKeywords(chunk.getKeywords());
                existing.setActive(chunk.isActive());
                KnowledgeChunkEntity saved = knowledgeRepository.save(existing);
                ragSourceSync.clearEmbeddingForChunk(saved.getId());
                return saved;
            });
    }

    public boolean delete(String tenantId, Long chunkId) {
        return knowledgeRepository.findById(chunkId)
            .filter(existing -> tenantId.equals(existing.getTenantId()))
            .map(existing -> {
                knowledgeRepository.deleteById(chunkId);
                return true;
            })
            .orElse(false);
    }
}

package com.botai.infrastructure.chatbot.rag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Invalida el vector de un chunk para que se regenere en el próximo ciclo de embeddings.
 */
@Component
public class KnowledgeChunkEmbeddingClearer {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeChunkEmbeddingClearer.class);

    private final JdbcTemplate jdbcTemplate;

    public KnowledgeChunkEmbeddingClearer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void clearEmbeddingForChunk(long chunkId) {
        int updated = jdbcTemplate.update("UPDATE knowledge_chunk SET embedding = NULL WHERE id = ?", chunkId);
        if (updated > 0) {
            log.info("[RAG] Embedding borrado para chunk id={} (se regenerará)", chunkId);
        }
    }
}

package com.botai.infrastructure.chatbot.rag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Invalida el vector del proveedor activo para regenerarlo en el próximo sync.
 */
@Component
public class KnowledgeChunkEmbeddingClearer {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeChunkEmbeddingClearer.class);

    private final JdbcTemplate jdbcTemplate;
    private final EmbeddingVectorStore vectorStore;

    public KnowledgeChunkEmbeddingClearer(JdbcTemplate jdbcTemplate, EmbeddingVectorStore vectorStore) {
        this.jdbcTemplate = jdbcTemplate;
        this.vectorStore = vectorStore;
    }

    public void clearEmbeddingForChunk(long chunkId) {
        int updated = jdbcTemplate.update(vectorStore.clearEmbeddingSql(), chunkId);
        if (updated > 0) {
            log.info("[RAG] {}=NULL para chunk id={} (se regenerará)", vectorStore.columnName(), chunkId);
        }
    }
}

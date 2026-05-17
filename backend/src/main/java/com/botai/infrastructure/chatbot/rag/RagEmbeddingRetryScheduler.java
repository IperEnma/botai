package com.botai.infrastructure.chatbot.rag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Reintenta embeddings pendientes (p. ej. tras fallo de cuota OpenRouter al arranque).
 */
@Component
@ConditionalOnBean(KnowledgeChunkEmbeddingSync.class)
public class RagEmbeddingRetryScheduler {

    private static final Logger log = LoggerFactory.getLogger(RagEmbeddingRetryScheduler.class);

    private final KnowledgeChunkEmbeddingSync embeddingSync;
    private final EmbeddingVectorStore vectorStore;
    private final long retryDelayMs;

    public RagEmbeddingRetryScheduler(KnowledgeChunkEmbeddingSync embeddingSync,
                                      EmbeddingVectorStore vectorStore,
                                      @Value("${bot.rag.embed-retry-delay-ms:600000}") long retryDelayMs) {
        this.embeddingSync = embeddingSync;
        this.vectorStore = vectorStore;
        this.retryDelayMs = Math.max(60_000L, retryDelayMs);
    }

    @Scheduled(fixedDelayString = "${bot.rag.embed-retry-delay-ms:600000}")
    public void retryPendingEmbeddings() {
        long pendingBefore = embeddingSync.countPendingEmbeddings();
        if (pendingBefore == 0) {
            return;
        }
        log.info("[RAG-EMBED] Retry programado (cada {} ms): {} chunk(s) sin vector en {}",
                retryDelayMs, pendingBefore, vectorStore.columnName());
        int filled = embeddingSync.syncPendingEmbeddings();
        long pendingAfter = embeddingSync.countPendingEmbeddings();
        if (filled > 0) {
            log.info("[RAG-EMBED] Retry programado: {} vector(es) generados; pendientes={}", filled, pendingAfter);
        } else if (pendingAfter > 0) {
            log.warn("[RAG-EMBED] Retry programado: siguen {} chunk(s) sin vector en {}", pendingAfter,
                    vectorStore.columnName());
        }
    }
}

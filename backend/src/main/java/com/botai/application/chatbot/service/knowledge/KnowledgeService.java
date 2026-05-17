package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.beans.factory.annotation.Value;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.IntSupplier;
import java.util.stream.IntStream;

/**
 * RAG: recupera fragmentos por búsqueda semántica (embeddings).
 * Sin fallbacks: debe haber EmbeddingModel y chunks con vector; si no, no hay resultados.
 */
public class KnowledgeService {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeService.class);
    private static final int DEFAULT_MAX_CHUNKS = 3;

    private static final long BACKFILL_COOLDOWN_MS = 120_000L;

    private final KnowledgeRepository knowledgeRepository;
    private final EmbeddingModel embeddingModel;
    /** Distancia coseno máxima (pgvector {@code <=>}); {@code null} = sin filtro. Equivale a similitud &ge; (1 - umbral). */
    private final Double maxCosineDistance;
    private final IntSupplier pendingEmbeddingBackfill;
    private final ConcurrentHashMap<String, Long> lastBackfillAttemptMs = new ConcurrentHashMap<>();

    public KnowledgeService(KnowledgeRepository knowledgeRepository,
                            EmbeddingModel embeddingModel,
                            @Value("${bot.rag.min-similarity:0}") double minSimilarity) {
        this(knowledgeRepository, embeddingModel, minSimilarity, () -> 0);
    }

    public KnowledgeService(KnowledgeRepository knowledgeRepository,
                            EmbeddingModel embeddingModel,
                            @Value("${bot.rag.min-similarity:0}") double minSimilarity,
                            IntSupplier pendingEmbeddingBackfill) {
        this.knowledgeRepository = knowledgeRepository;
        this.embeddingModel = embeddingModel;
        this.pendingEmbeddingBackfill = pendingEmbeddingBackfill != null ? pendingEmbeddingBackfill : () -> 0;
        this.maxCosineDistance = (minSimilarity > 0 && minSimilarity < 1) ? (1.0 - minSimilarity) : null;
        if (this.maxCosineDistance != null) {
            log.info("[RAG] Filtro similitud activo: min-similarity={} -> distancia coseno máxima {}", minSimilarity, this.maxCosineDistance);
        }
    }

    /**
     * Devuelve los fragmentos más relevantes para la consulta (solo búsqueda semántica).
     * Requiere EmbeddingModel configurado y chunks con embedding; sin fallback.
     */
    public List<KnowledgeChunk> findRelevant(String query, int maxChunks, String tenantId) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        if (embeddingModel == null) {
            log.error("[RAG] EmbeddingModel no configurado: definí BOT_EMBEDDING_PROVIDER (djl o api). Sin fallback.");
            return List.of();
        }
        int limit = maxChunks > 0 ? maxChunks : DEFAULT_MAX_CHUNKS;
        List<KnowledgeChunk> result = findRelevantByEmbedding(query, limit, tenantId);
        if (result.isEmpty() && tenantId != null && !tenantId.isBlank()) {
            long total = knowledgeRepository.countActiveByTenantId(tenantId);
            if (total > 0 && tryBackfillEmbeddings(tenantId)) {
                result = findRelevantByEmbedding(query, limit, tenantId);
            }
        }
        if (result.isEmpty() && tenantId != null && !tenantId.isBlank()) {
            long total = knowledgeRepository.countActiveByTenantId(tenantId);
            log.warn("[RAG] 0 chunks para tenantId={} query='{}' (chunks activos: {}). "
                    + "Si activos>0: columna embedding_* probablemente NULL — revisá logs [RAG-EMBED] y OPENROUTER_API_KEY.",
                    tenantId, query, total);
        } else if (!result.isEmpty()) {
            log.info("[RAG] {} chunks para tenantId={} query='{}'", result.size(), tenantId, query);
        }
        return result;
    }

    private List<KnowledgeChunk> findRelevantByEmbedding(String query, int limit, String tenantId) {
        try {
            EmbeddingResponse resp = embeddingModel.embedForResponse(List.of(query));
            if (resp.getResults() == null || resp.getResults().isEmpty()) {
                log.warn("[RAG] EmbeddingModel devolvió resultados vacíos para query='{}'", query);
                return List.of();
            }
            List<Double> vector = toListOfDouble(resp.getResults().get(0).getOutput());
            if (vector.isEmpty()) {
                log.warn("[RAG] Vector de embedding vacío para query='{}'", query);
                return List.of();
            }
            return knowledgeRepository.findRelevantBySimilarity(vector, limit, tenantId, maxCosineDistance);
        } catch (Exception e) {
            log.error("[RAG] Error en búsqueda por embedding para tenantId={} query='{}': {} — {}", tenantId, query, e.getMessage(), e.getClass().getSimpleName(), e);
            return List.of();
        }
    }

    private boolean tryBackfillEmbeddings(String tenantId) {
        long now = System.currentTimeMillis();
        Long last = lastBackfillAttemptMs.get(tenantId);
        if (last != null && now - last < BACKFILL_COOLDOWN_MS) {
            return false;
        }
        lastBackfillAttemptMs.put(tenantId, now);
        int filled = pendingEmbeddingBackfill.getAsInt();
        if (filled > 0) {
            log.info("[RAG] Backfill bajo demanda tenantId={}: {} embedding(s) generados; reintentando búsqueda",
                    tenantId, filled);
            return true;
        }
        return false;
    }

    private static List<Double> toListOfDouble(Object output) {
        if (output instanceof float[] fa) {
            return IntStream.range(0, fa.length).mapToObj(i -> (double) fa[i]).toList();
        }
        if (output instanceof List<?> list) {
            return list.stream().map(o -> ((Number) o).doubleValue()).toList();
        }
        return List.of();
    }
}

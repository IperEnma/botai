package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.util.List;
import java.util.stream.IntStream;

/**
 * RAG: recupera fragmentos por búsqueda semántica (embeddings).
 * Sin fallbacks: debe haber EmbeddingModel y chunks con vector; si no, no hay resultados.
 */
public class KnowledgeService {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeService.class);
    private static final int DEFAULT_MAX_CHUNKS = 5;

    private final KnowledgeRepository knowledgeRepository;
    private final EmbeddingModel embeddingModel;

    public KnowledgeService(KnowledgeRepository knowledgeRepository, EmbeddingModel embeddingModel) {
        this.knowledgeRepository = knowledgeRepository;
        this.embeddingModel = embeddingModel;
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
            log.error("[RAG] EmbeddingModel no configurado: RAG requiere modelo de embeddings (Ollama). Sin fallback.");
            return List.of();
        }
        int limit = maxChunks > 0 ? maxChunks : DEFAULT_MAX_CHUNKS;
        List<KnowledgeChunk> result = findRelevantByEmbedding(query, limit, tenantId);
        if (result.isEmpty() && tenantId != null && !tenantId.isBlank()) {
            long total = knowledgeRepository.countActiveByTenantId(tenantId);
            log.warn("[RAG] 0 chunks para tenantId={} query='{}' (chunks activos: {}). Revisar: embeddings generados (sync al guardar horario/servicios), modelo y dimensión 768).", tenantId, query, total);
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
            return knowledgeRepository.findRelevantBySimilarity(vector, limit, tenantId);
        } catch (Exception e) {
            log.error("[RAG] Error en búsqueda por embedding para tenantId={} query='{}': {} — {}", tenantId, query, e.getMessage(), e.getClass().getSimpleName(), e);
            return List.of();
        }
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

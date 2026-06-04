package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.model.KnowledgeChunkHit;

import java.util.List;

/**
 * Port for RAG knowledge chunks. Implementation in infrastructure (JPA + vector search).
 */
public interface KnowledgeRepository {

    List<KnowledgeChunk> findAllActive();

    List<KnowledgeChunk> findAllActiveByTenantId(String tenantId);

    /** Cuenta chunks activos del tenant (para diagnóstico cuando RAG devuelve 0). */
    long countActiveByTenantId(String tenantId);

    /**
     * Búsqueda por similitud (cosine) en la columna del proveedor activo (embedding_384 / embedding_1536).
     * Filtra por tenantId cuando no es nulo.
     *
     * @param maxCosineDistance si no es {@code null}, descarta filas con distancia coseno mayor (pgvector {@code <=>});
     *                          equivale a similitud coseno &ge; {@code 1 - maxCosineDistance} para vectores normalizados.
     */
    default List<KnowledgeChunk> findRelevantBySimilarity(List<Double> queryEmbedding, int limit, String tenantId) {
        return findRelevantBySimilarity(queryEmbedding, limit, tenantId, null);
    }

    List<KnowledgeChunk> findRelevantBySimilarity(List<Double> queryEmbedding, int limit, String tenantId,
                                                  Double maxCosineDistance);

    /**
     * Igual que {@link #findRelevantBySimilarity} pero devuelve distancia coseno por fila.
     * {@code topicPrefixes} vacío = sin filtro por topic; si no vacío, solo chunks cuyo topic empieza con algún prefijo.
     */
    List<KnowledgeChunkHit> findRelevantBySimilarityScored(List<Double> queryEmbedding, int limit, String tenantId,
                                                           Double maxCosineDistance, List<String> topicPrefixes);
}

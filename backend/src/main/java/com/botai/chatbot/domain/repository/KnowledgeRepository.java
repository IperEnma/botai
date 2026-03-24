package com.botai.chatbot.domain.repository;

import com.botai.chatbot.domain.model.KnowledgeChunk;

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
     * Búsqueda por similitud (cosine) usando la columna embedding. Solo devuelve chunks con embedding no nulo.
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
}

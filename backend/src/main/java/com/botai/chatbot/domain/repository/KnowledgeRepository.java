package com.botai.chatbot.domain.repository;

import com.botai.chatbot.domain.model.KnowledgeChunk;

import java.util.List;

/**
 * Port for RAG knowledge chunks. Implementation in infrastructure (JPA + vector search).
 */
public interface KnowledgeRepository {

    List<KnowledgeChunk> findAllActive();

    List<KnowledgeChunk> findAllActiveByTenantId(String tenantId);

    /**
     * Búsqueda por similitud (cosine) usando la columna embedding. Solo devuelve chunks con embedding no nulo.
     * Filtra por tenantId cuando no es nulo.
     */
    List<KnowledgeChunk> findRelevantBySimilarity(List<Double> queryEmbedding, int limit, String tenantId);
}

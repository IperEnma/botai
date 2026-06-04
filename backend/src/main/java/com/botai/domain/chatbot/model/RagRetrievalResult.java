package com.botai.domain.chatbot.model;

import java.util.List;

/**
 * Resultado de recuperación RAG (Fase 1: expansión de query, filtro topic, CRAG).
 */
public record RagRetrievalResult(
        List<KnowledgeChunk> chunks,
        boolean cragRejected,
        String retrievalQuery,
        List<String> topicPrefixes,
        double avgSimilarity
) {
    public static RagRetrievalResult empty(String retrievalQuery, List<String> topicPrefixes, boolean cragRejected) {
        return new RagRetrievalResult(List.of(), cragRejected, retrievalQuery, topicPrefixes, 0.0);
    }
}

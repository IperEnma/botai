package com.botai.domain.chatbot.model;

import java.util.List;

/**
 * Resultado de recuperación RAG por turno (query expandida, filtro topic, gate CRAG).
 */
public record RagRetrievalResult(
        List<KnowledgeChunk> chunks,
        boolean cragRejected,
        String retrievalQuery,
        List<String> topicPrefixes,
        double avgSimilarity,
        List<BotLesson> activeLessons
) {
    public RagRetrievalResult(List<KnowledgeChunk> chunks, boolean cragRejected, String retrievalQuery,
                              List<String> topicPrefixes, double avgSimilarity) {
        this(chunks, cragRejected, retrievalQuery, topicPrefixes, avgSimilarity, List.of());
    }

    public static RagRetrievalResult empty(String retrievalQuery, List<String> topicPrefixes, boolean cragRejected) {
        return new RagRetrievalResult(List.of(), cragRejected, retrievalQuery, topicPrefixes, 0.0, List.of());
    }
}

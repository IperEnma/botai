package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * RAG: recupera fragmentos de conocimiento relevantes para una consulta.
 * Usa búsqueda semántica (embeddings) cuando hay modelo y vectores; si no, usa coincidencia de palabras.
 */
public class KnowledgeService {

    private static final int DEFAULT_MAX_CHUNKS = 5;
    private static final int MIN_WORD_LENGTH = 2;

    private final KnowledgeRepository knowledgeRepository;
    private final EmbeddingModel embeddingModel;

    public KnowledgeService(KnowledgeRepository knowledgeRepository, EmbeddingModel embeddingModel) {
        this.knowledgeRepository = knowledgeRepository;
        this.embeddingModel = embeddingModel;
    }

    /**
     * Devuelve los fragmentos más relevantes para la consulta del tenant.
     * Si hay EmbeddingModel y chunks con embedding, usa búsqueda por similitud; si no, por palabras.
     * tenantId puede ser null para búsqueda global (retrocompatibilidad).
     */
    public List<KnowledgeChunk> findRelevant(String query, int maxChunks, String tenantId) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        int limit = maxChunks > 0 ? maxChunks : DEFAULT_MAX_CHUNKS;

        if (embeddingModel != null) {
            List<KnowledgeChunk> bySimilarity = findRelevantByEmbedding(query, limit, tenantId);
            if (!bySimilarity.isEmpty()) {
                return bySimilarity;
            }
        }
        return findRelevantByKeywords(query, limit, tenantId);
    }

    private List<KnowledgeChunk> findRelevantByEmbedding(String query, int limit, String tenantId) {
        try {
            EmbeddingResponse resp = embeddingModel.embedForResponse(List.of(query));
            if (resp.getResults() == null || resp.getResults().isEmpty()) {
                return List.of();
            }
            List<Double> vector = toListOfDouble(resp.getResults().get(0).getOutput());
            if (vector.isEmpty()) {
                return List.of();
            }
            return knowledgeRepository.findRelevantBySimilarity(vector, limit, tenantId);
        } catch (Exception e) {
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

    /**
     * Búsqueda por palabras clave (fallback cuando no hay embeddings).
     */
    private List<KnowledgeChunk> findRelevantByKeywords(String query, int limit, String tenantId) {
        Set<String> queryWords = toNormalizedWords(query);
        if (queryWords.isEmpty()) {
            return List.of();
        }
        List<KnowledgeChunk> all = tenantId != null && !tenantId.isBlank()
            ? knowledgeRepository.findAllActiveByTenantId(tenantId)
            : knowledgeRepository.findAllActive();
        if (all.isEmpty()) {
            return List.of();
        }
        return all.stream()
            .map(chunk -> new ScoredChunk(chunk, score(chunk, queryWords)))
            .filter(sc -> sc.score > 0)
            .sorted(Comparator.comparingInt((ScoredChunk sc) -> sc.score).reversed())
            .limit(limit)
            .map(sc -> sc.chunk)
            .collect(Collectors.toList());
    }

    private static Set<String> toNormalizedWords(String text) {
        return Arrays.stream(text.toLowerCase().split("\\s+"))
            .map(w -> w.replaceAll("[^a-záéíóúñü0-9]", ""))
            .filter(w -> w.length() >= MIN_WORD_LENGTH)
            .collect(Collectors.toSet());
    }

    private int score(KnowledgeChunk chunk, Set<String> queryWords) {
        Set<String> chunkWords = new HashSet<>();
        chunkWords.addAll(toNormalizedWords(chunk.getTopic()));
        chunkWords.addAll(toNormalizedWords(chunk.getContent()));
        chunkWords.addAll(toNormalizedWords(chunk.getKeywords()));
        return (int) queryWords.stream().filter(chunkWords::contains).count();
    }

    private static class ScoredChunk {
        final KnowledgeChunk chunk;
        final int score;

        ScoredChunk(KnowledgeChunk chunk, int score) {
            this.chunk = chunk;
            this.score = score;
        }
    }
}

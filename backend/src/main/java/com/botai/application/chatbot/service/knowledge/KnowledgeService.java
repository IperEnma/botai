package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.model.KnowledgeChunkHit;
import com.botai.domain.chatbot.model.RagRetrievalResult;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.beans.factory.annotation.Value;

import java.text.Normalizer;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.IntSupplier;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * RAG: recupera fragmentos por búsqueda semántica (embeddings).
 * Si hay chunks activos pero sin embedding, aplica fallback por texto (p. ej. nombre del negocio).
 */
public class KnowledgeService {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeService.class);
    private static final int DEFAULT_MAX_CHUNKS = 3;
    private static final Pattern NON_WORD = Pattern.compile("[^\\p{L}\\p{N}]+");
    private static final String BUSINESS_INFO_TOPIC_PREFIX = "Agenda: Información del negocio";
    private static final String BUSINESS_HOURS_TOPIC_PREFIX = "Agenda: Horarios";

    private static final long BACKFILL_COOLDOWN_MS = 120_000L;

    private final KnowledgeRepository knowledgeRepository;
    private final EmbeddingModel embeddingModel;
    /** Distancia coseno máxima (pgvector {@code <=>}); {@code null} = sin filtro. Equivale a similitud &ge; (1 - umbral). */
    private final Double maxCosineDistance;
    private final IntSupplier pendingEmbeddingBackfill;
    private final ConcurrentHashMap<String, Long> lastBackfillAttemptMs = new ConcurrentHashMap<>();
    private final boolean phase1Enabled;
    private final int phase1HistoryTurns;
    private final double phase1MinAvgSimilarity;
    private final double phase1MinChunkSimilarity;
    private final int phase1PrefetchMultiplier;

    public KnowledgeService(KnowledgeRepository knowledgeRepository,
                            EmbeddingModel embeddingModel,
                            @Value("${bot.rag.min-similarity:0}") double minSimilarity) {
        this(knowledgeRepository, embeddingModel, minSimilarity, () -> 0,
                true, 2, 0.52, 0.40, 2);
    }

    public KnowledgeService(KnowledgeRepository knowledgeRepository,
                            EmbeddingModel embeddingModel,
                            @Value("${bot.rag.min-similarity:0}") double minSimilarity,
                            IntSupplier pendingEmbeddingBackfill) {
        this(knowledgeRepository, embeddingModel, minSimilarity, pendingEmbeddingBackfill,
                true, 2, 0.52, 0.40, 2);
    }

    public KnowledgeService(KnowledgeRepository knowledgeRepository,
                            EmbeddingModel embeddingModel,
                            double minSimilarity,
                            IntSupplier pendingEmbeddingBackfill,
                            boolean phase1Enabled,
                            int phase1HistoryTurns,
                            double phase1MinAvgSimilarity,
                            double phase1MinChunkSimilarity,
                            int phase1PrefetchMultiplier) {
        this.knowledgeRepository = knowledgeRepository;
        this.embeddingModel = embeddingModel;
        this.pendingEmbeddingBackfill = pendingEmbeddingBackfill != null ? pendingEmbeddingBackfill : () -> 0;
        this.maxCosineDistance = (minSimilarity > 0 && minSimilarity < 1) ? (1.0 - minSimilarity) : null;
        this.phase1Enabled = phase1Enabled;
        this.phase1HistoryTurns = Math.max(0, phase1HistoryTurns);
        this.phase1MinAvgSimilarity = clamp01(phase1MinAvgSimilarity);
        this.phase1MinChunkSimilarity = clamp01(phase1MinChunkSimilarity);
        this.phase1PrefetchMultiplier = Math.max(1, phase1PrefetchMultiplier);
        if (this.maxCosineDistance != null) {
            log.info("[RAG] Filtro similitud activo: min-similarity={} -> distancia coseno máxima {}", minSimilarity, this.maxCosineDistance);
        }
        if (phase1Enabled) {
            log.info("[RAG] Fase 1 activa: historyTurns={} minAvgSim={} minChunkSim={} prefetch×{}",
                    this.phase1HistoryTurns, this.phase1MinAvgSimilarity, this.phase1MinChunkSimilarity, this.phase1PrefetchMultiplier);
        }
    }

    public boolean isPhase1Enabled() {
        return phase1Enabled;
    }

    /**
     * Recuperación Fase 1: query expandida, filtro topic, CRAG. Si Fase 1 está desactivada, delega en {@link #findRelevant}.
     */
    public RagRetrievalResult retrieveForTurn(String userMessage, int maxChunks, String tenantId,
                                              List<String> historyLines) {
        if (!phase1Enabled) {
            List<KnowledgeChunk> legacy = findRelevant(userMessage, maxChunks, tenantId);
            return new RagRetrievalResult(legacy, false, userMessage, List.of(), legacy.isEmpty() ? 0.0 : 0.75);
        }
        int limit = maxChunks > 0 ? maxChunks : DEFAULT_MAX_CHUNKS;
        String retrievalQuery = RagQueryExpander.buildRetrievalQuery(userMessage, historyLines, phase1HistoryTurns);
        List<String> topicPrefixes = RagTopicHintService.topicPrefixesForQuery(retrievalQuery);
        int prefetch = limit * phase1PrefetchMultiplier;

        List<KnowledgeChunkHit> hits = findScoredHits(retrievalQuery, prefetch, tenantId, topicPrefixes);
        if (hits.isEmpty() && !topicPrefixes.isEmpty()) {
            log.info("[RAG] Fase1 sin hits con topics {} -> reintento sin filtro topic", topicPrefixes);
            hits = findScoredHits(retrievalQuery, prefetch, tenantId, List.of());
        }

        List<KnowledgeChunkHit> passed = hits.stream()
                .filter(h -> h.similarity() >= phase1MinChunkSimilarity)
                .limit(limit)
                .toList();

        if (!passed.isEmpty()) {
            double avg = passed.stream().mapToDouble(KnowledgeChunkHit::similarity).average().orElse(0.0);
            if (avg >= phase1MinAvgSimilarity) {
                List<KnowledgeChunk> chunks = passed.stream().map(KnowledgeChunkHit::chunk).toList();
                log.info("[RAG] Fase1 OK tenantId={} topics={} avgSim={} chunks={}",
                        tenantId, topicPrefixes, String.format(Locale.ROOT, "%.3f", avg), chunks.size());
                return new RagRetrievalResult(chunks, false, retrievalQuery, topicPrefixes, avg);
            }
            log.info("[RAG] Fase1 CRAG rechazado (avgSim {} < {}) tenantId={} query='{}'",
                    String.format(Locale.ROOT, "%.3f", avg), phase1MinAvgSimilarity, tenantId, retrievalQuery);
            return RagRetrievalResult.empty(retrievalQuery, topicPrefixes, true);
        }

        List<KnowledgeChunk> fallback = findRelevantByTextFallback(retrievalQuery, limit, tenantId, topicPrefixes);
        if (fallback.isEmpty() && !topicPrefixes.isEmpty()) {
            fallback = findRelevantByTextFallback(retrievalQuery, limit, tenantId, List.of());
        }
        if (!fallback.isEmpty()) {
            log.info("[RAG] Fase1 fallback texto: {} chunk(s) tenantId={}", fallback.size(), tenantId);
            return new RagRetrievalResult(fallback, false, retrievalQuery, topicPrefixes, 0.58);
        }

        log.info("[RAG] Fase1 CRAG sin chunks tenantId={} query='{}'", tenantId, retrievalQuery);
        return RagRetrievalResult.empty(retrievalQuery, topicPrefixes, true);
    }

    /**
     * Devuelve los fragmentos más relevantes para la consulta (búsqueda semántica con fallback textual).
     */
    public List<KnowledgeChunk> findRelevant(String query, int maxChunks, String tenantId) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        int limit = maxChunks > 0 ? maxChunks : DEFAULT_MAX_CHUNKS;
        List<KnowledgeChunk> result = List.of();
        if (embeddingModel != null) {
            result = findRelevantByEmbedding(query, limit, tenantId);
            if (result.isEmpty() && tenantId != null && !tenantId.isBlank()) {
                long total = knowledgeRepository.countActiveByTenantId(tenantId);
                if (total > 0 && tryBackfillEmbeddings(tenantId)) {
                    result = findRelevantByEmbedding(query, limit, tenantId);
                }
            }
        } else {
            log.warn("[RAG] EmbeddingModel no configurado: definí BOT_EMBEDDING_PROVIDER (djl o api). Usando fallback textual.");
        }
        if (result.isEmpty() && tenantId != null && !tenantId.isBlank()) {
            long total = knowledgeRepository.countActiveByTenantId(tenantId);
            if (total > 0) {
                result = findRelevantByTextFallback(query, limit, tenantId, List.of());
                if (!result.isEmpty()) {
                    log.info("[RAG] Fallback texto: {} chunk(s) para tenantId={} query='{}' (embeddings NULL o sin match semántico)",
                            result.size(), tenantId, query);
                    return result;
                }
            }
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

    private List<KnowledgeChunkHit> findScoredHits(String query, int limit, String tenantId, List<String> topicPrefixes) {
        if (embeddingModel == null || query == null || query.isBlank()) {
            return List.of();
        }
        try {
            EmbeddingResponse resp = embeddingModel.embedForResponse(List.of(query));
            if (resp.getResults() == null || resp.getResults().isEmpty()) {
                return List.of();
            }
            List<Double> vector = toListOfDouble(resp.getResults().get(0).getOutput());
            if (vector.isEmpty()) {
                return List.of();
            }
            List<KnowledgeChunkHit> hits = knowledgeRepository.findRelevantBySimilarityScored(
                    vector, limit, tenantId, maxCosineDistance, topicPrefixes);
            if (hits.isEmpty() && tenantId != null && !tenantId.isBlank()) {
                long total = knowledgeRepository.countActiveByTenantId(tenantId);
                if (total > 0 && tryBackfillEmbeddings(tenantId)) {
                    hits = knowledgeRepository.findRelevantBySimilarityScored(
                            vector, limit, tenantId, maxCosineDistance, topicPrefixes);
                }
            }
            return hits;
        } catch (Exception e) {
            log.error("[RAG] Fase1 error embedding tenantId={} query='{}': {}", tenantId, query, e.getMessage());
            return List.of();
        }
    }

    private List<KnowledgeChunk> findRelevantByTextFallback(String query, int limit, String tenantId,
                                                             List<String> topicPrefixes) {
        List<KnowledgeChunk> active = knowledgeRepository.findAllActiveByTenantId(tenantId);
        if (active.isEmpty()) {
            return List.of();
        }
        if (topicPrefixes != null && !topicPrefixes.isEmpty()) {
            active = active.stream()
                    .filter(c -> matchesTopicPrefix(c.getTopic(), topicPrefixes))
                    .toList();
            if (active.isEmpty()) {
                return List.of();
            }
        }
        String normalizedQuery = normalizeForMatch(query);
        Set<String> queryTokens = tokenize(normalizedQuery);

        if (looksLikeBusinessIdentityQuery(normalizedQuery)) {
            List<KnowledgeChunk> businessInfo = active.stream()
                    .filter(this::isBusinessInfoChunk)
                    .limit(limit)
                    .toList();
            if (!businessInfo.isEmpty()) {
                return businessInfo;
            }
        }

        List<KnowledgeChunk> ranked = active.stream()
                .sorted(Comparator
                        .comparingInt((KnowledgeChunk c) -> scoreChunk(c, queryTokens, normalizedQuery))
                        .reversed()
                        .thenComparing(c -> isBusinessInfoChunk(c) ? 0 : 1))
                .limit(limit)
                .toList();

        if (ranked.stream().anyMatch(c -> scoreChunk(c, queryTokens, normalizedQuery) > 0)) {
            return ranked;
        }
        return active.stream().limit(limit).toList();
    }

    private boolean isBusinessInfoChunk(KnowledgeChunk chunk) {
        return chunk.getTopic() != null && chunk.getTopic().startsWith(BUSINESS_INFO_TOPIC_PREFIX);
    }

    private boolean looksLikeBusinessIdentityQuery(String normalizedQuery) {
        if (normalizedQuery == null || normalizedQuery.isBlank()) {
            return false;
        }
        return normalizedQuery.contains("nombre")
                || normalizedQuery.contains("llaman")
                || normalizedQuery.contains("llama ")
                || normalizedQuery.contains("negocio")
                || normalizedQuery.contains("comercial")
                || normalizedQuery.contains("quienes son")
                || normalizedQuery.contains("como se llaman");
    }

    private int scoreChunk(KnowledgeChunk chunk, Set<String> queryTokens, String normalizedQuery) {
        String haystack = normalizeForMatch(
                chunk.getTopic() + " " + chunk.getContent() + " " + chunk.getKeywords());
        int score = 0;
        for (String token : queryTokens) {
            if (token.length() >= 3 && haystack.contains(token)) {
                score += token.length() >= 5 ? 3 : 1;
            }
        }
        if (isBusinessInfoChunk(chunk) && looksLikeBusinessIdentityQuery(normalizedQuery)) {
            score += 10;
        }
        return score;
    }

    private static Set<String> tokenize(String normalizedText) {
        if (normalizedText == null || normalizedText.isBlank()) {
            return Set.of();
        }
        return NON_WORD.splitAsStream(normalizedText)
                .filter(t -> t.length() >= 2)
                .collect(Collectors.toSet());
    }

    private static String normalizeForMatch(String text) {
        if (text == null) {
            return "";
        }
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .trim();
        return normalized;
    }

    private static boolean matchesTopicPrefix(String topic, List<String> prefixes) {
        if (topic == null || prefixes == null) {
            return false;
        }
        for (String prefix : prefixes) {
            if (prefix != null && topic.startsWith(prefix)) {
                return true;
            }
        }
        return false;
    }

    private static double clamp01(double v) {
        if (v < 0) {
            return 0;
        }
        if (v > 1) {
            return 1;
        }
        return v;
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

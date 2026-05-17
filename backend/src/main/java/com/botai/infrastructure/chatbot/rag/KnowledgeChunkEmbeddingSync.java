package com.botai.infrastructure.chatbot.rag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.context.event.EventListener;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.IntStream;

/**
 * Rellena la columna de embedding activa ({@link EmbeddingVectorStore}) para chunks sin vector.
 */
@Component
@ConditionalOnBean(EmbeddingModel.class)
public class KnowledgeChunkEmbeddingSync {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeChunkEmbeddingSync.class);

    private final JdbcTemplate jdbcTemplate;
    private final EmbeddingModel embeddingModel;
    private final EmbeddingVectorStore vectorStore;

    public KnowledgeChunkEmbeddingSync(JdbcTemplate jdbcTemplate,
                                       EmbeddingModel embeddingModel,
                                       EmbeddingVectorStore vectorStore) {
        this.jdbcTemplate = jdbcTemplate;
        this.embeddingModel = embeddingModel;
        this.vectorStore = vectorStore;
    }

    public long countPendingEmbeddings() {
        Long count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM knowledge_chunk WHERE active = true AND "
                        + vectorStore.columnName() + " IS NULL",
                Long.class);
        return count != null ? count : 0L;
    }

    public int syncPendingEmbeddings() {
        List<Row> rows = jdbcTemplate.query(vectorStore.selectPendingEmbeddingsSql(),
            (rs, rowNum) -> new Row(rs.getLong("id"), rs.getString("topic"), rs.getString("content")));
        if (rows.isEmpty()) {
            log.debug("[RAG-EMBED] Sin chunks pendientes en {} (columna activa, dims={})",
                    vectorStore.columnName(), vectorStore.dimensions());
            return 0;
        }
        log.info("[RAG-EMBED] Sync en {}: {} chunks sin vector", vectorStore.columnName(), rows.size());
        int updated = 0;
        int failed = 0;
        for (Row row : rows) {
            try {
                String textToEmbed = (row.topic + " " + row.content).trim();
                EmbeddingResponse resp = embeddingModel.embedForResponse(List.of(textToEmbed));
                if (resp.getResults() == null || resp.getResults().isEmpty()) {
                    log.warn("[RAG-EMBED] Chunk id={} topic='{}': modelo no devolvió resultado", row.id, row.topic);
                    failed++;
                    continue;
                }
                List<Double> vector = toListOfDouble(resp.getResults().get(0).getOutput());
                vectorStore.requireMatchingSize(vector.size());
                if (vector.isEmpty()) {
                    log.warn("[RAG-EMBED] Chunk id={} topic='{}': vector vacío", row.id, row.topic);
                    failed++;
                    continue;
                }
                String vectorStr = toVectorString(vector);
                jdbcTemplate.update(vectorStore.updateEmbeddingSql(), vectorStr, row.id);
                updated++;
            } catch (Exception e) {
                log.error("[RAG-EMBED] Chunk id={} topic='{}': {} — {}", row.id, row.topic, e.getMessage(),
                        e.getClass().getSimpleName(), e);
                failed++;
            }
        }
        log.info("[RAG-EMBED] Fin sync {}: actualizados={} fallidos={} pendientes_restantes={}",
                vectorStore.columnName(), updated, failed, countPendingEmbeddings());
        if (failed > 0) {
            log.warn("[RAG-EMBED] Falló la generación de {} vector(es). Revisá OPENROUTER_API_KEY, cuota del modelo "
                    + "({}) y logs [RAG-EMBED] anteriores.", failed, vectorStore.columnName());
        }
        return updated;
    }

    @Order(Ordered.LOWEST_PRECEDENCE)
    @EventListener(ApplicationReadyEvent.class)
    public void syncEmbeddingsOnStartup() {
        syncPendingEmbeddings();
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

    private static String toVectorString(List<Double> embedding) {
        return "[" + String.join(",", embedding.stream().map(String::valueOf).toList()) + "]";
    }

    private record Row(long id, String topic, String content) {}
}

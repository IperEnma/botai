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
 * Rellena la columna embedding de knowledge_chunk para chunks activos que aún no la tienen.
 * Se ejecuta al arranque si hay un EmbeddingModel disponible.
 */
@Component
@ConditionalOnBean(EmbeddingModel.class)
public class KnowledgeChunkEmbeddingSync {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeChunkEmbeddingSync.class);

    private static final String SELECT_NEEDING_EMBEDDING =
        "SELECT id, topic, content FROM knowledge_chunk WHERE active = true AND embedding IS NULL";
    private static final String UPDATE_EMBEDDING =
        "UPDATE knowledge_chunk SET embedding = CAST(? AS vector) WHERE id = ?";

    private final JdbcTemplate jdbcTemplate;
    private final EmbeddingModel embeddingModel;

    public KnowledgeChunkEmbeddingSync(JdbcTemplate jdbcTemplate, EmbeddingModel embeddingModel) {
        this.jdbcTemplate = jdbcTemplate;
        this.embeddingModel = embeddingModel;
    }

    /**
     * Rellena embeddings de chunks que tienen embedding IS NULL.
     * Se llama al arranque y también tras refrescar horario/servicios para que la búsqueda semántica los encuentre.
     */
    public int syncPendingEmbeddings() {
        List<Row> rows = jdbcTemplate.query(SELECT_NEEDING_EMBEDDING,
            (rs, rowNum) -> new Row(rs.getLong("id"), rs.getString("topic"), rs.getString("content")));
        if (rows.isEmpty()) {
            log.info("[RAG-EMBED] Sin chunks pendientes de embedding (todos tienen vector o no hay chunks activos)");
            return 0;
        }
        log.info("[RAG-EMBED] Iniciando sync: {} chunks sin vector (ids: {})", rows.size(),
            rows.stream().map(r -> r.id).toList());
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
                if (vector.isEmpty()) {
                    log.warn("[RAG-EMBED] Chunk id={} topic='{}': vector vacío", row.id, row.topic);
                    failed++;
                    continue;
                }
                String vectorStr = toVectorString(vector);
                jdbcTemplate.update(UPDATE_EMBEDDING, vectorStr, row.id);
                updated++;
                log.debug("[RAG-EMBED] Chunk id={} topic='{}': embedding guardado", row.id, row.topic);
            } catch (Exception e) {
                log.error("[RAG-EMBED] Chunk id={} topic='{}': {} — {}", row.id, row.topic, e.getMessage(), e.getClass().getSimpleName(), e);
                failed++;
            }
        }
        log.info("[RAG-EMBED] Fin sync: actualizados={} fallidos={} total={}", updated, failed, rows.size());
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

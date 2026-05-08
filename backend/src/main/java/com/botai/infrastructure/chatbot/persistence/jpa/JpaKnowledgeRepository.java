package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.stream.Collectors;

@Repository
public class JpaKnowledgeRepository implements KnowledgeRepository {

    private static final Logger log = LoggerFactory.getLogger(JpaKnowledgeRepository.class);

    private static final String SIMILARITY_SQL_TENANT =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL AND tenant_id = ? " +
        "ORDER BY embedding <=> CAST(? AS vector) LIMIT ?";
    private static final String SIMILARITY_SQL_GLOBAL =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL " +
        "ORDER BY embedding <=> CAST(? AS vector) LIMIT ?";
    /** Filtro por distancia coseno (pgvector {@code <=>}); solo filas con distancia &le; umbral. */
    private static final String SIMILARITY_SQL_TENANT_FILTERED =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL AND tenant_id = ? " +
        "AND (embedding <=> CAST(? AS vector)) <= ? " +
        "ORDER BY embedding <=> CAST(? AS vector) LIMIT ?";
    private static final String SIMILARITY_SQL_GLOBAL_FILTERED =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL " +
        "AND (embedding <=> CAST(? AS vector)) <= ? " +
        "ORDER BY embedding <=> CAST(? AS vector) LIMIT ?";

    private final KnowledgeChunkJpaRepository jpaRepository;
    private final JdbcTemplate jdbcTemplate;

    public JpaKnowledgeRepository(KnowledgeChunkJpaRepository jpaRepository, JdbcTemplate jdbcTemplate) {
        this.jpaRepository = jpaRepository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<KnowledgeChunk> findAllActive() {
        return jpaRepository.findByActiveTrue().stream()
            .map(this::toChunk)
            .collect(Collectors.toList());
    }

    @Override
    public List<KnowledgeChunk> findAllActiveByTenantId(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return List.of();
        }
        return jpaRepository.findByTenantIdAndActiveTrue(tenantId).stream()
            .map(this::toChunk)
            .collect(Collectors.toList());
    }

    @Override
    public long countActiveByTenantId(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return 0;
        }
        return jpaRepository.countByTenantIdAndActiveTrue(tenantId);
    }

    @Override
    public List<KnowledgeChunk> findRelevantBySimilarity(List<Double> queryEmbedding, int limit, String tenantId,
                                                         Double maxCosineDistance) {
        if (queryEmbedding == null || queryEmbedding.isEmpty() || limit <= 0) {
            log.debug("[RAG-REPO] findRelevantBySimilarity omitido: embedding vacío o limit<=0");
            return List.of();
        }
        String vectorStr = toVectorString(queryEmbedding);
        List<KnowledgeChunk> result;
        boolean filtered = maxCosineDistance != null && maxCosineDistance > 0;
        if (tenantId != null && !tenantId.isBlank()) {
            if (filtered) {
                result = jdbcTemplate.query(SIMILARITY_SQL_TENANT_FILTERED,
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    tenantId, vectorStr, maxCosineDistance, vectorStr, limit);
            } else {
                result = jdbcTemplate.query(SIMILARITY_SQL_TENANT,
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    tenantId, vectorStr, limit);
            }
        } else {
            if (filtered) {
                result = jdbcTemplate.query(SIMILARITY_SQL_GLOBAL_FILTERED,
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    vectorStr, maxCosineDistance, vectorStr, limit);
            } else {
                result = jdbcTemplate.query(SIMILARITY_SQL_GLOBAL,
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    vectorStr, limit);
            }
        }
        if (result.isEmpty()) {
            log.warn("[RAG-REPO] findRelevantBySimilarity: 0 filas para tenantId={} (¿chunks sin embedding, umbral muy estricto o sin datos?)", tenantId);
        }
        return result;
    }

    private static String toVectorString(List<Double> embedding) {
        return "[" + embedding.stream().map(d -> String.valueOf(d)).reduce((a, b) -> a + "," + b).orElse("") + "]";
    }

    private KnowledgeChunk toChunk(KnowledgeChunkEntity e) {
        return new KnowledgeChunk(e.getTopic(), e.getContent(), e.getKeywords());
    }
}

package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.domain.model.KnowledgeChunk;
import com.botai.chatbot.domain.repository.KnowledgeRepository;
import com.botai.chatbot.infrastructure.persistence.entity.KnowledgeChunkEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.stream.Collectors;

@Repository
public class JpaKnowledgeRepository implements KnowledgeRepository {

    private static final String SIMILARITY_SQL_TENANT =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL AND tenant_id = ? " +
        "ORDER BY embedding <=> CAST(? AS vector) LIMIT ?";
    private static final String SIMILARITY_SQL_GLOBAL =
        "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk " +
        "WHERE active = true AND embedding IS NOT NULL " +
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
    public List<KnowledgeChunk> findRelevantBySimilarity(List<Double> queryEmbedding, int limit, String tenantId) {
        if (queryEmbedding == null || queryEmbedding.isEmpty() || limit <= 0) {
            return List.of();
        }
        String vectorStr = toVectorString(queryEmbedding);
        if (tenantId != null && !tenantId.isBlank()) {
            return jdbcTemplate.query(SIMILARITY_SQL_TENANT,
                (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                tenantId, vectorStr, limit);
        }
        return jdbcTemplate.query(SIMILARITY_SQL_GLOBAL,
            (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
            vectorStr, limit);
    }

    private static String toVectorString(List<Double> embedding) {
        return "[" + embedding.stream().map(d -> String.valueOf(d)).reduce((a, b) -> a + "," + b).orElse("") + "]";
    }

    private KnowledgeChunk toChunk(KnowledgeChunkEntity e) {
        return new KnowledgeChunk(e.getTopic(), e.getContent(), e.getKeywords());
    }
}

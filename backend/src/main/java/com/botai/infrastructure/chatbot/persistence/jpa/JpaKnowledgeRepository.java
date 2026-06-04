package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.model.KnowledgeChunkHit;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import com.botai.infrastructure.chatbot.rag.EmbeddingVectorStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Repository
public class JpaKnowledgeRepository implements KnowledgeRepository {

    private static final Logger log = LoggerFactory.getLogger(JpaKnowledgeRepository.class);

    private final KnowledgeChunkJpaRepository jpaRepository;
    private final JdbcTemplate jdbcTemplate;
    private final EmbeddingVectorStore vectorStore;

    public JpaKnowledgeRepository(KnowledgeChunkJpaRepository jpaRepository,
                                  JdbcTemplate jdbcTemplate,
                                  EmbeddingVectorStore vectorStore) {
        this.jpaRepository = jpaRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.vectorStore = vectorStore;
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
        vectorStore.requireMatchingSize(queryEmbedding.size());
        String vectorStr = toVectorString(queryEmbedding);
        List<KnowledgeChunk> result;
        boolean filtered = maxCosineDistance != null && maxCosineDistance > 0;
        if (tenantId != null && !tenantId.isBlank()) {
            if (filtered) {
                result = jdbcTemplate.query(vectorStore.similaritySqlTenant(true),
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    tenantId, vectorStr, maxCosineDistance, vectorStr, limit);
            } else {
                result = jdbcTemplate.query(vectorStore.similaritySqlTenant(false),
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    tenantId, vectorStr, limit);
            }
        } else {
            if (filtered) {
                result = jdbcTemplate.query(vectorStore.similaritySqlGlobal(true),
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    vectorStr, maxCosineDistance, vectorStr, limit);
            } else {
                result = jdbcTemplate.query(vectorStore.similaritySqlGlobal(false),
                    (rs, rowNum) -> new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                    vectorStr, limit);
            }
        }
        if (result.isEmpty()) {
            log.warn("[RAG-REPO] 0 filas para tenantId={} (columna {}, ¿sin vector o umbral alto?)",
                    tenantId, vectorStore.columnName());
        }
        return result;
    }

    @Override
    public List<KnowledgeChunkHit> findRelevantBySimilarityScored(List<Double> queryEmbedding, int limit, String tenantId,
                                                                  Double maxCosineDistance,
                                                                  List<String> topicPrefixes) {
        if (queryEmbedding == null || queryEmbedding.isEmpty() || limit <= 0) {
            return List.of();
        }
        vectorStore.requireMatchingSize(queryEmbedding.size());
        String vectorStr = toVectorString(queryEmbedding);
        String col = vectorStore.columnName();
        TopicClause topic = TopicClause.fromPrefixes(topicPrefixes);
        boolean filtered = maxCosineDistance != null && maxCosineDistance > 0;

        StringBuilder sql = new StringBuilder(256);
        sql.append("SELECT topic, content, COALESCE(keywords, ''), (").append(col)
                .append(" <=> CAST(? AS vector)) AS dist FROM knowledge_chunk WHERE active = true AND ")
                .append(col).append(" IS NOT NULL ");
        if (tenantId != null && !tenantId.isBlank()) {
            sql.append("AND tenant_id = ? ");
        }
        sql.append(topic.sql);
        if (filtered) {
            sql.append("AND (").append(col).append(" <=> CAST(? AS vector)) <= ? ");
        }
        sql.append("ORDER BY ").append(col).append(" <=> CAST(? AS vector) LIMIT ?");

        List<Object> params = new ArrayList<>();
        params.add(vectorStr);
        if (tenantId != null && !tenantId.isBlank()) {
            params.add(tenantId);
        }
        params.addAll(topic.params);
        if (filtered) {
            params.add(vectorStr);
            params.add(maxCosineDistance);
        }
        params.add(vectorStr);
        params.add(limit);

        return jdbcTemplate.query(sql.toString(), params.toArray(),
                (rs, rowNum) -> new KnowledgeChunkHit(
                        new KnowledgeChunk(rs.getString(1), rs.getString(2), rs.getString(3)),
                        rs.getDouble(4)));
    }

    private record TopicClause(String sql, List<Object> params) {
        static TopicClause fromPrefixes(List<String> prefixes) {
            if (prefixes == null || prefixes.isEmpty()) {
                return new TopicClause("", List.of());
            }
            List<Object> params = new ArrayList<>();
            StringBuilder clause = new StringBuilder("AND (");
            for (int i = 0; i < prefixes.size(); i++) {
                if (i > 0) {
                    clause.append(" OR ");
                }
                clause.append("topic LIKE ?");
                String p = prefixes.get(i);
                params.add(p != null && p.endsWith("%") ? p : p + "%");
            }
            clause.append(") ");
            return new TopicClause(clause.toString(), params);
        }
    }

    private static String toVectorString(List<Double> embedding) {
        return "[" + embedding.stream().map(String::valueOf).reduce((a, b) -> a + "," + b).orElse("") + "]";
    }

    private KnowledgeChunk toChunk(KnowledgeChunkEntity e) {
        return new KnowledgeChunk(e.getTopic(), e.getContent(), e.getKeywords());
    }
}

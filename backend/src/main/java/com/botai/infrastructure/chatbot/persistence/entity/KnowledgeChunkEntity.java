package com.botai.infrastructure.chatbot.persistence.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "knowledge_chunk", indexes = {
    @Index(name = "idx_knowledge_tenant", columnList = "tenant_id"),
    @Index(name = "idx_knowledge_topic", columnList = "topic"),
    @Index(name = "idx_knowledge_active", columnList = "active"),
    @Index(name = "idx_knowledge_chunk_business_id", columnList = "business_id")
})
public class KnowledgeChunkEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    /**
     * Sucursal Agenda ({@code agenda_businesses.id}). Null en fragmentos manuales del panel;
     * obligatorio en filas generadas por {@code AgendaRagSourceSync}.
     */
    @Column(name = "business_id")
    private UUID businessId;

    @Column(name = "topic", nullable = false, length = 255)
    private String topic;

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }

    public UUID getBusinessId() {
        return businessId;
    }

    public void setBusinessId(UUID businessId) {
        this.businessId = businessId;
    }

    @Column(name = "content", nullable = false, columnDefinition = "text")
    private String content;

    @Column(name = "keywords", columnDefinition = "text")
    private String keywords;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at")
    private Instant createdAt;

    /** Origen del fragmento: MANUAL, AGENDA_SYNC, FAQ_HINT, etc. */
    @Column(name = "source_type", length = 64)
    private String sourceType;

    @Column(name = "language", length = 16)
    private String language;

    /** Si está definido, el chunk deja de usarse en retrieval después de esta fecha. */
    @Column(name = "valid_until")
    private Instant validUntil;

    /**
     * Vectores RAG por dimensión (pgvector). Solo JDBC — ver {@link com.botai.infrastructure.chatbot.rag.EmbeddingVectorStore}.
     * DJL local → {@code embedding_384}; OpenRouter/API → {@code embedding_1536}.
     */
    @Column(name = "embedding_384", columnDefinition = "vector(384)", insertable = false, updatable = false)
    private String embedding384;

    @Column(name = "embedding_1536", columnDefinition = "vector(1536)", insertable = false, updatable = false)
    private String embedding1536;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTopic() {
        return topic;
    }

    public void setTopic(String topic) {
        this.topic = topic;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getKeywords() {
        return keywords;
    }

    public void setKeywords(String keywords) {
        this.keywords = keywords;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public Instant getValidUntil() {
        return validUntil;
    }

    public void setValidUntil(Instant validUntil) {
        this.validUntil = validUntil;
    }

    public String getEmbedding384() {
        return embedding384;
    }

    public String getEmbedding1536() {
        return embedding1536;
    }
}

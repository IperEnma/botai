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

    /** Vectores RAG; dimensión 384 = DJL MiniLM (ver EMBEDDING_SETUP.md). */
    @Column(name = "embedding", columnDefinition = "vector(384)")
    private String embedding;

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

    public String getEmbedding() {
        return embedding;
    }

    public void setEmbedding(String embedding) {
        this.embedding = embedding;
    }
}

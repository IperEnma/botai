package com.botai.chatbot.infrastructure.persistence.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "knowledge_chunk", indexes = {
    @Index(name = "idx_knowledge_tenant", columnList = "tenant_id"),
    @Index(name = "idx_knowledge_topic", columnList = "topic"),
    @Index(name = "idx_knowledge_active", columnList = "active")
})
public class KnowledgeChunkEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "topic", nullable = false, length = 255)
    private String topic;

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }

    @Column(name = "content", nullable = false, columnDefinition = "text")
    private String content;

    @Column(name = "keywords", columnDefinition = "text")
    private String keywords;

    @Column(name = "active", nullable = false)
    private boolean active = true;

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
}

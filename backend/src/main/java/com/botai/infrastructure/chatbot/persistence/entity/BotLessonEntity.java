package com.botai.infrastructure.chatbot.persistence.entity;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "bot_lesson", indexes = {
    @Index(name = "idx_bot_lesson_tenant", columnList = "tenant_id"),
    @Index(name = "idx_bot_lesson_active", columnList = "active")
})
public class BotLessonEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "name", nullable = false, length = 128)
    private String name;

    @Column(name = "trigger_keywords", nullable = false, columnDefinition = "text")
    private String triggerKeywords;

    @Column(name = "content", nullable = false, columnDefinition = "text")
    private String content;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at")
    private Instant createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getTriggerKeywords() { return triggerKeywords; }
    public void setTriggerKeywords(String triggerKeywords) { this.triggerKeywords = triggerKeywords; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

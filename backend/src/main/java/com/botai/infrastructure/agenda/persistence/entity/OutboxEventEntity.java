package com.botai.infrastructure.agenda.persistence.entity;

import com.botai.domain.agenda.model.OutboxEvent;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/** Índice parcial {@code idx_agenda_outbox_pending}: V3__agenda_orm_supplements.sql */
@Entity
@Table(name = "agenda_outbox_events")
public class OutboxEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "event_type", nullable = false, length = 100)
    private String eventType;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload", nullable = false, columnDefinition = "jsonb")
    private String payload;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    protected OutboxEventEntity() {}

    public OutboxEventEntity(String eventType, String payload, String status,
                              LocalDateTime createdAt, LocalDateTime processedAt) {
        this.eventType   = eventType;
        this.payload     = payload;
        this.status      = status;
        this.createdAt   = createdAt;
        this.processedAt = processedAt;
    }

    public UUID getId()                  { return id; }
    public String getEventType()         { return eventType; }
    public String getPayload()           { return payload; }
    public String getStatus()            { return status; }
    public LocalDateTime getCreatedAt()  { return createdAt; }
    public LocalDateTime getProcessedAt(){ return processedAt; }

    public void setStatus(String status)               { this.status = status; }
    public void setProcessedAt(LocalDateTime processedAt){ this.processedAt = processedAt; }

    public OutboxEvent toDomain() {
        return new OutboxEvent(id, eventType, payload, status, createdAt, processedAt);
    }

    public static OutboxEventEntity fromDomain(OutboxEvent e) {
        OutboxEventEntity entity = new OutboxEventEntity(
                e.getEventType(), e.getPayload(), e.getStatus(),
                e.getCreatedAt() != null ? e.getCreatedAt() : LocalDateTime.now(),
                e.getProcessedAt());
        return entity;
    }
}

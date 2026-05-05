package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.UUID;

/** Evento pendiente de publicación persistido en la tabla {@code agenda_outbox_events}. */
public final class OutboxEvent {

    public static final String STATUS_PENDING   = "PENDING";
    public static final String STATUS_PROCESSED = "PROCESSED";

    private final UUID id;
    private final String eventType;
    private final String payload;
    private final String status;
    private final LocalDateTime createdAt;
    private final LocalDateTime processedAt;

    public OutboxEvent(UUID id, String eventType, String payload, String status,
                       LocalDateTime createdAt, LocalDateTime processedAt) {
        this.id          = id;
        this.eventType   = eventType;
        this.payload     = payload;
        this.status      = status;
        this.createdAt   = createdAt;
        this.processedAt = processedAt;
    }

    public UUID getId()                { return id; }
    public String getEventType()       { return eventType; }
    public String getPayload()         { return payload; }
    public String getStatus()          { return status; }
    public LocalDateTime getCreatedAt(){ return createdAt; }
    public LocalDateTime getProcessedAt(){ return processedAt; }

    public OutboxEvent markProcessed(LocalDateTime at) {
        return new OutboxEvent(id, eventType, payload, STATUS_PROCESSED, createdAt, at);
    }
}

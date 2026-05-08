package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

public final class Notification {

    private final UUID id;
    private final UUID businessId;
    private final UUID userId;
    private final NotificationCanal canal;
    private final String titulo;
    private final String cuerpo;
    private final NotificationEstado estado;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Notification(UUID id, UUID businessId, UUID userId,
                        NotificationCanal canal, String titulo, String cuerpo,
                        NotificationEstado estado,
                        LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.canal = Objects.requireNonNull(canal, "canal");
        this.titulo = Objects.requireNonNull(titulo, "titulo");
        this.cuerpo = Objects.requireNonNull(cuerpo, "cuerpo");
        this.estado = Objects.requireNonNull(estado, "estado");
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public UUID getUserId() { return userId; }
    public NotificationCanal getCanal() { return canal; }
    public String getTitulo() { return titulo; }
    public String getCuerpo() { return cuerpo; }
    public NotificationEstado getEstado() { return estado; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

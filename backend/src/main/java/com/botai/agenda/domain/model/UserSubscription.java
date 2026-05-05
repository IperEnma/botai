package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Suscripción activa (o histórica) de un usuario contra un negocio específico.
 *
 * <p>Equivale a la "billetera" del usuario: guarda el saldo actual y las fechas
 * de vigencia. Es la fila sobre la que se toma {@code PESSIMISTIC_WRITE} al
 * confirmar reservas para evitar doble descuento (ver Sprint 3).</p>
 */
public final class UserSubscription {

    private final UUID id;
    private final UUID userId;
    private final UUID planId;
    private final UUID businessId;
    private final int saldoActual;
    private final LocalDateTime fechaInicio;
    private final LocalDateTime fechaExpiracion;
    private final SubscriptionEstado estado;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public UserSubscription(UUID id,
                            UUID userId,
                            UUID planId,
                            UUID businessId,
                            int saldoActual,
                            LocalDateTime fechaInicio,
                            LocalDateTime fechaExpiracion,
                            SubscriptionEstado estado,
                            LocalDateTime createdAt,
                            LocalDateTime updatedAt) {
        this.id = id;
        this.userId = Objects.requireNonNull(userId, "userId");
        this.planId = Objects.requireNonNull(planId, "planId");
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        if (saldoActual < 0) {
            throw new IllegalArgumentException("saldoActual no puede ser negativo");
        }
        this.saldoActual = saldoActual;
        this.fechaInicio = Objects.requireNonNull(fechaInicio, "fechaInicio");
        this.fechaExpiracion = Objects.requireNonNull(fechaExpiracion, "fechaExpiracion");
        if (fechaExpiracion.isBefore(fechaInicio)) {
            throw new IllegalArgumentException("fechaExpiracion no puede ser anterior a fechaInicio");
        }
        this.estado = Objects.requireNonNull(estado, "estado");
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public UUID getPlanId() { return planId; }
    public UUID getBusinessId() { return businessId; }
    public int getSaldoActual() { return saldoActual; }
    public LocalDateTime getFechaInicio() { return fechaInicio; }
    public LocalDateTime getFechaExpiracion() { return fechaExpiracion; }
    public SubscriptionEstado getEstado() { return estado; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

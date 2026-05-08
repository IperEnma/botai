package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Reserva individual que un usuario hace contra un servicio de un negocio.
 *
 * <p>POJO inmutable. Toda la lógica de transición de estado vive en
 * {@code BookingDomainService} y en los use cases; este objeto solo mantiene
 * las invariantes estructurales (fechas coherentes, estado no nulo).</p>
 *
 * <p>{@code subscriptionId} es opcional: si la reserva se paga con saldo de
 * una suscripción, acá va el id; si no, queda null (ej. reservas creadas por
 * un admin manualmente, fuera del flujo de billetera).</p>
 */
public final class Booking {

    private final UUID id;
    private final UUID businessId;
    private final UUID serviceId;
    private final UUID userId;
    private final UUID subscriptionId; // nullable
    private final UUID staffMemberId;  // nullable
    private final LocalDateTime fechaHoraInicio;
    private final LocalDateTime fechaHoraFin;
    private final BookingEstado estado;
    private final String notas;
    private final LocalDateTime canceladaAt;
    private final LocalDateTime completadaAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Booking(UUID id,
                   UUID businessId,
                   UUID serviceId,
                   UUID userId,
                   UUID subscriptionId,
                   UUID staffMemberId,
                   LocalDateTime fechaHoraInicio,
                   LocalDateTime fechaHoraFin,
                   BookingEstado estado,
                   String notas,
                   LocalDateTime canceladaAt,
                   LocalDateTime completadaAt,
                   LocalDateTime createdAt,
                   LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.serviceId = Objects.requireNonNull(serviceId, "serviceId");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.subscriptionId = subscriptionId;
        this.staffMemberId = staffMemberId;
        this.fechaHoraInicio = Objects.requireNonNull(fechaHoraInicio, "fechaHoraInicio");
        this.fechaHoraFin = Objects.requireNonNull(fechaHoraFin, "fechaHoraFin");
        if (!fechaHoraFin.isAfter(fechaHoraInicio)) {
            throw new IllegalArgumentException("fechaHoraFin debe ser posterior a fechaHoraInicio");
        }
        this.estado = Objects.requireNonNull(estado, "estado");
        this.notas = notas;
        this.canceladaAt = canceladaAt;
        this.completadaAt = completadaAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public UUID getServiceId() { return serviceId; }
    public UUID getUserId() { return userId; }
    public UUID getSubscriptionId() { return subscriptionId; }
    public UUID getStaffMemberId() { return staffMemberId; }
    public LocalDateTime getFechaHoraInicio() { return fechaHoraInicio; }
    public LocalDateTime getFechaHoraFin() { return fechaHoraFin; }
    public BookingEstado getEstado() { return estado; }
    public String getNotas() { return notas; }
    public LocalDateTime getCanceladaAt() { return canceladaAt; }
    public LocalDateTime getCompletadaAt() { return completadaAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

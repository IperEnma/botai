package com.botai.infrastructure.agenda.persistence.entity;

import com.botai.domain.agenda.model.BookingEstado;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Tabla creada por Hibernate. Anti doble reserva: {@code excl_agenda_bookings_slot} en
 * {@code V3__agenda_orm_supplements.sql} (EXCLUDE GiST; JPA no lo modela).
 */
@Entity
@Table(
        name = "agenda_bookings",
        indexes = {
                @Index(name = "idx_agenda_bookings_business_fecha", columnList = "business_id, fecha_hora_inicio"),
                @Index(name = "idx_agenda_bookings_user_estado", columnList = "user_id, estado, fecha_hora_inicio")
        })
@Check(constraints = "estado IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW')")
@Check(constraints = "fecha_hora_fin > fecha_hora_inicio")
public class BookingEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "service_id", nullable = false)
    private UUID serviceId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "subscription_id")
    private UUID subscriptionId;

    @Column(name = "staff_member_id")
    private UUID staffMemberId;

    @Column(name = "fecha_hora_inicio", nullable = false)
    private LocalDateTime fechaHoraInicio;

    @Column(name = "fecha_hora_fin", nullable = false)
    private LocalDateTime fechaHoraFin;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 16)
    private BookingEstado estado;

    @Column(name = "notas")
    private String notas;

    @Column(name = "cancelada_at")
    private LocalDateTime canceladaAt;

    @Column(name = "completada_at")
    private LocalDateTime completadaAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public UUID getServiceId() { return serviceId; }
    public void setServiceId(UUID serviceId) { this.serviceId = serviceId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getSubscriptionId() { return subscriptionId; }
    public void setSubscriptionId(UUID subscriptionId) { this.subscriptionId = subscriptionId; }
    public UUID getStaffMemberId() { return staffMemberId; }
    public void setStaffMemberId(UUID staffMemberId) { this.staffMemberId = staffMemberId; }
    public LocalDateTime getFechaHoraInicio() { return fechaHoraInicio; }
    public void setFechaHoraInicio(LocalDateTime fechaHoraInicio) { this.fechaHoraInicio = fechaHoraInicio; }
    public LocalDateTime getFechaHoraFin() { return fechaHoraFin; }
    public void setFechaHoraFin(LocalDateTime fechaHoraFin) { this.fechaHoraFin = fechaHoraFin; }
    public BookingEstado getEstado() { return estado; }
    public void setEstado(BookingEstado estado) { this.estado = estado; }
    public String getNotas() { return notas; }
    public void setNotas(String notas) { this.notas = notas; }
    public LocalDateTime getCanceladaAt() { return canceladaAt; }
    public void setCanceladaAt(LocalDateTime canceladaAt) { this.canceladaAt = canceladaAt; }
    public LocalDateTime getCompletadaAt() { return completadaAt; }
    public void setCompletadaAt(LocalDateTime completadaAt) { this.completadaAt = completadaAt; }
}

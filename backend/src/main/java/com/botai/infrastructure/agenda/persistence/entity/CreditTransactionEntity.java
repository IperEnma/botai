package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;

import java.util.UUID;

import com.botai.domain.agenda.model.CreditMotivo;

/**
 * Movimiento inmutable en la billetera. Conceptualmente nunca se actualiza; extendemos
 * {@link BaseAuditableEntity} por consistencia con el resto del módulo — el
 * {@code updated_at} solo se setea al insertar y queda estable.
 */
@Entity
@Table(
        name = "agenda_credit_transactions",
        indexes = @Index(name = "idx_act_subscription_created", columnList = "subscription_id, created_at"))
@Check(constraints = "motivo IN ('RESERVA','CANCELACION_DEVUELTA','AJUSTE_ADMIN','COMPRA')")
public class CreditTransactionEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "subscription_id", nullable = false)
    private UUID subscriptionId;

    @Column(name = "monto", nullable = false)
    private int monto;

    @Enumerated(EnumType.STRING)
    @Column(name = "motivo", nullable = false, length = 24)
    private CreditMotivo motivo;

    @Column(name = "booking_id")
    private UUID bookingId;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getSubscriptionId() { return subscriptionId; }
    public void setSubscriptionId(UUID subscriptionId) { this.subscriptionId = subscriptionId; }
    public int getMonto() { return monto; }
    public void setMonto(int monto) { this.monto = monto; }
    public CreditMotivo getMotivo() { return motivo; }
    public void setMotivo(CreditMotivo motivo) { this.motivo = motivo; }
    public UUID getBookingId() { return bookingId; }
    public void setBookingId(UUID bookingId) { this.bookingId = bookingId; }
}

package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Movimiento inmutable en la "billetera" de una suscripción.
 *
 * <p>Se usa como <b>libro mayor</b>: nunca se actualiza, solo se inserta. Cada
 * cambio de saldo en {@code UserSubscription} debe venir acompañado de una
 * {@code CreditTransaction} con el signo correspondiente (+/-).</p>
 */
public final class CreditTransaction {

    private final UUID id;
    private final UUID subscriptionId;
    private final int monto;          // positivo = crédito, negativo = débito
    private final CreditMotivo motivo;
    private final UUID bookingId;     // nullable (COMPRA y AJUSTE_ADMIN no vienen de booking)
    private final LocalDateTime createdAt;

    public CreditTransaction(UUID id,
                             UUID subscriptionId,
                             int monto,
                             CreditMotivo motivo,
                             UUID bookingId,
                             LocalDateTime createdAt) {
        this.id = id;
        this.subscriptionId = Objects.requireNonNull(subscriptionId, "subscriptionId");
        this.monto = monto;
        this.motivo = Objects.requireNonNull(motivo, "motivo");
        this.bookingId = bookingId;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getSubscriptionId() { return subscriptionId; }
    public int getMonto() { return monto; }
    public CreditMotivo getMotivo() { return motivo; }
    public UUID getBookingId() { return bookingId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}

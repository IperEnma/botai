package com.botai.domain.agenda.model;

/**
 * Motivo de un movimiento en {@code agenda_credit_transactions}.
 *
 * <ul>
 *   <li>{@link #COMPRA}: el usuario compró una suscripción (crédito inicial).</li>
 *   <li>{@link #RESERVA}: una reserva descontó saldo (negativo) o movió 0 para trazabilidad
 *       en planes ILIMITADO_MENSUAL.</li>
 *   <li>{@link #CANCELACION_DEVUELTA}: el usuario canceló a tiempo y se reintegra el crédito.</li>
 *   <li>{@link #AJUSTE_ADMIN}: ajuste manual por parte del admin de negocio.</li>
 * </ul>
 */
public enum CreditMotivo {
    COMPRA,
    RESERVA,
    CANCELACION_DEVUELTA,
    AJUSTE_ADMIN
}

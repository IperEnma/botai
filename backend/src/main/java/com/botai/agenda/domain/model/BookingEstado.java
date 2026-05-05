package com.botai.agenda.domain.model;

/**
 * Ciclo de vida de una reserva.
 *
 * <ul>
 *   <li>{@code PENDING}: creada pero aún no confirmada (no descuenta crédito).</li>
 *   <li>{@code CONFIRMED}: reserva activa, ya descontó crédito si aplicaba.</li>
 *   <li>{@code CANCELLED}: cancelada; puede haber devuelto crédito si estuvo
 *       dentro de la ventana configurada.</li>
 *   <li>{@code COMPLETED}: sesión ocurrida.</li>
 *   <li>{@code NO_SHOW}: el usuario no se presentó.</li>
 * </ul>
 */
public enum BookingEstado {
    PENDING,
    CONFIRMED,
    CANCELLED,
    COMPLETED,
    NO_SHOW
}

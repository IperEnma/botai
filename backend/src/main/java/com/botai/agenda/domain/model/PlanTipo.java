package com.botai.agenda.domain.model;

/**
 * Tipos de plan (regla de cómo se consume/valida el saldo).
 *
 * <ul>
 *   <li>{@link #ILIMITADO_MENSUAL}: acceso sin descontar créditos mientras esté vigente.</li>
 *   <li>{@link #POR_CREDITOS}: cada reserva descuenta 1 crédito.</li>
 *   <li>{@link #SOLO_RESERVA}: permite agendar sin créditos (p. ej. pago al asistir).</li>
 *   <li>{@link #MIXTO}: combina créditos + posibilidad de reservar sin saldo (la semántica
 *       se refina en {@code CreditDomainService} en Slice 2).</li>
 * </ul>
 */
public enum PlanTipo {
    ILIMITADO_MENSUAL,
    POR_CREDITOS,
    SOLO_RESERVA,
    MIXTO
}

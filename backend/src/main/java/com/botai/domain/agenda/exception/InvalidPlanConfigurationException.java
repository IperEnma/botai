package com.botai.domain.agenda.exception;

/**
 * Validaciones de reglas de negocio al crear/actualizar un plan, p. ej.:
 * <ul>
 *   <li>{@code POR_CREDITOS} o {@code MIXTO} requieren {@code totalCreditos > 0}.</li>
 *   <li>{@code ILIMITADO_MENSUAL} o {@code SOLO_RESERVA} no deben declarar créditos.</li>
 *   <li>{@code validezDias <= 0}.</li>
 * </ul>
 *
 * <p>Se mapea a {@code 400 BAD_REQUEST}.</p>
 */
public class InvalidPlanConfigurationException extends AgendaDomainException {
    public InvalidPlanConfigurationException(String message) {
        super(message);
    }
}

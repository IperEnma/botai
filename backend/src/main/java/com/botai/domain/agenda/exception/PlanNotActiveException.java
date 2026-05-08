package com.botai.domain.agenda.exception;

import java.util.UUID;

/**
 * Se intentó comprar / suscribirse a un plan con {@code activo=false}. Se mapea
 * a {@code 409 Conflict} porque el recurso existe pero no acepta nuevas ventas.
 */
public class PlanNotActiveException extends AgendaDomainException {

    public PlanNotActiveException(UUID planId) {
        super("El plan no está activo para nuevas suscripciones: " + planId);
    }
}

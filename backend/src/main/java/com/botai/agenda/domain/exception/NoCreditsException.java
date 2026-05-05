package com.botai.agenda.domain.exception;

import java.util.UUID;

/**
 * La suscripción no tiene saldo suficiente para descontar una sesión. Se mapea
 * a {@code 409 Conflict}: el recurso existe pero su estado impide la operación.
 */
public class NoCreditsException extends AgendaDomainException {

    public NoCreditsException(UUID subscriptionId) {
        super("La suscripción no tiene créditos disponibles: " + subscriptionId);
    }
}

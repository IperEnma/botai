package com.botai.agenda.domain.exception;

import java.util.UUID;

/**
 * La suscripción ya venció (o no está activa). Se mapea a {@code 409 Conflict}.
 */
public class SubscriptionExpiredException extends AgendaDomainException {

    public SubscriptionExpiredException(UUID subscriptionId) {
        super("La suscripción no está vigente: " + subscriptionId);
    }
}

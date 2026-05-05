package com.botai.agenda.domain.exception;

import java.util.UUID;

public class UserSubscriptionNotFoundException extends AgendaDomainException {
    public UserSubscriptionNotFoundException(UUID id) {
        super("Suscripción no encontrada: " + id);
    }
}

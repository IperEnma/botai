package com.botai.agenda.domain.exception;

import java.util.UUID;

public class ServiceNotFoundException extends AgendaDomainException {

    public ServiceNotFoundException(UUID id) {
        super("Servicio no encontrado: " + id);
    }
}

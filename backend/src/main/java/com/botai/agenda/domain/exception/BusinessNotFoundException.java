package com.botai.agenda.domain.exception;

import java.util.UUID;

public class BusinessNotFoundException extends AgendaDomainException {
    public BusinessNotFoundException(UUID id) {
        super("Negocio no encontrado: " + id);
    }
}

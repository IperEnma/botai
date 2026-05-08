package com.botai.domain.agenda.exception;

import java.util.UUID;

public class BusinessNotFoundException extends AgendaDomainException {
    public BusinessNotFoundException(UUID id) {
        super("Negocio no encontrado: " + id);
    }
}

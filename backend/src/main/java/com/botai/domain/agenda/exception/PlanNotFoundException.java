package com.botai.domain.agenda.exception;

import java.util.UUID;

public class PlanNotFoundException extends AgendaDomainException {
    public PlanNotFoundException(UUID id) {
        super("Plan no encontrado: " + id);
    }
}

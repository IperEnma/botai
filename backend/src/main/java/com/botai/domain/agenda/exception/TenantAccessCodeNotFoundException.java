package com.botai.domain.agenda.exception;

/** Código de acceso de 8 caracteres no asociado a ninguna cuenta. */
public class TenantAccessCodeNotFoundException extends AgendaDomainException {

    public TenantAccessCodeNotFoundException() {
        super("Código de acceso no encontrado.");
    }
}

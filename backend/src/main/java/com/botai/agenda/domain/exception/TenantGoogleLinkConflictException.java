package com.botai.agenda.domain.exception;

/** El correo de Google ya está vinculado o el negocio ya tiene otro correo vinculado. */
public class TenantGoogleLinkConflictException extends AgendaDomainException {

    public TenantGoogleLinkConflictException(String message) {
        super(message);
    }
}

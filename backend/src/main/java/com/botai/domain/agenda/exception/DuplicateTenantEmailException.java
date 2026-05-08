package com.botai.domain.agenda.exception;

/**
 * Se lanza cuando se intenta registrar un tenant con un email que ya existe.
 */
public class DuplicateTenantEmailException extends AgendaDomainException {

    public DuplicateTenantEmailException(String email) {
        super("Email ya registrado: " + email);
    }
}

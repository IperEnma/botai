package com.botai.domain.agenda.exception;

/** Excepción base de dominio para el módulo AGENDA. */
public abstract class AgendaDomainException extends RuntimeException {

    protected AgendaDomainException(String message) {
        super(message);
    }

    protected AgendaDomainException(String message, Throwable cause) {
        super(message, cause);
    }
}

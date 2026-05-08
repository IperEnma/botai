package com.botai.domain.agenda.exception;

/** Ya existe un tenant con este número (identificador de cuenta por WhatsApp). */
public class DuplicateTenantNumeroException extends AgendaDomainException {

    public DuplicateTenantNumeroException(String numero) {
        super("Número ya registrado: " + numero);
    }
}

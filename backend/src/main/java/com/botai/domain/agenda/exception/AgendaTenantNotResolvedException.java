package com.botai.domain.agenda.exception;

/**
 * El JWT no está asociado a ningún tenant Agenda (cuenta no registrada o sin vincular).
 * Se expone como 404 para no revelar el módulo ni el estado de registro.
 */
public class AgendaTenantNotResolvedException extends RuntimeException {

    public AgendaTenantNotResolvedException() {
        super("No hay tenant Agenda para este usuario.");
    }
}

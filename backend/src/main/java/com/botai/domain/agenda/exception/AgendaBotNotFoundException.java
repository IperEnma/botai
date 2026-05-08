package com.botai.domain.agenda.exception;

/** Bot de workspace inexistente (tabla {@code bot}). */
public class AgendaBotNotFoundException extends AgendaDomainException {
    public AgendaBotNotFoundException(long botId) {
        super("Bot no encontrado: id=" + botId);
    }
}

package com.botai.domain.agenda.exception;

/** El {@code bot.id} no pertenece al {@code tenant_id} del espacio Agenda actual. */
public class WorkspaceBotMismatchException extends AgendaDomainException {
    public WorkspaceBotMismatchException() {
        super("El bot no pertenece a este espacio de trabajo (tenant distinto).");
    }
}

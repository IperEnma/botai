package com.botai.domain.agenda.exception;

import java.util.UUID;

public class CancellationNotAllowedException extends AgendaDomainException {

    public CancellationNotAllowedException(UUID bookingId, int hoursCancellationLimit) {
        super("La reserva " + bookingId + " no puede cancelarse: la ventana de "
                + hoursCancellationLimit + "h antes del inicio ya cerró.");
    }
}

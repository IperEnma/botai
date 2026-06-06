package com.botai.domain.agenda.exception;

import java.util.UUID;

public class BookingNotCompletedException extends AgendaDomainException {
    public BookingNotCompletedException(UUID bookingId) {
        super("El turno no está completado, no se puede dejar una reseña: " + bookingId);
    }
}

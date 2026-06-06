package com.botai.domain.agenda.exception;

import java.util.UUID;

public class ReviewAlreadyExistsException extends AgendaDomainException {
    public ReviewAlreadyExistsException(UUID bookingId) {
        super("Ya existe una reseña para la reserva: " + bookingId);
    }
}

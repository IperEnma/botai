package com.botai.domain.agenda.exception;

import java.util.UUID;

public class BookingNotFoundException extends AgendaDomainException {

    public BookingNotFoundException(UUID id) {
        super("Reserva no encontrada: " + id);
    }
}

package com.botai.agenda.domain.exception;

import com.botai.agenda.domain.model.BookingEstado;

import java.util.UUID;

public class BookingNotCancellableException extends AgendaDomainException {

    public BookingNotCancellableException(UUID bookingId, BookingEstado estado) {
        super("La reserva " + bookingId + " no se puede cancelar en estado " + estado + ".");
    }
}

package com.botai.domain.agenda.exception;

import com.botai.domain.agenda.model.BookingEstado;

import java.util.UUID;

public class BookingNotCancellableException extends AgendaDomainException {

    public BookingNotCancellableException(UUID bookingId, BookingEstado estado) {
        super("La reserva " + bookingId + " no se puede cancelar en estado " + estado + ".");
    }
}

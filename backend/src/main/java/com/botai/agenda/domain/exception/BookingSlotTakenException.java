package com.botai.agenda.domain.exception;

/**
 * Se intentó reservar un slot que se pisa con otra reserva activa. Se mapea a
 * {@code 409 Conflict}.
 */
public class BookingSlotTakenException extends AgendaDomainException {

    public BookingSlotTakenException() {
        super("El horario seleccionado ya está ocupado");
    }
}

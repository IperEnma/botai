package com.botai.agenda.application.dto;

/** Turno disponible devuelto por el endpoint público de disponibilidad. */
public record AvailabilitySlotResponse(
        String inicio,
        String fin
) {
}

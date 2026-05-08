package com.botai.application.agenda.dto;

/** Turno disponible devuelto por el endpoint público de disponibilidad. */
public record AvailabilitySlotResponse(
        String inicio,
        String fin
) {
}

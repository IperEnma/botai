package com.botai.application.agenda.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Payload para crear una reserva desde el flujo de usuario final.
 *
 * <p>El {@code userId} viene por header {@code X-User-Id}; el {@code businessId}
 * y {@code tenantId} viajan en el path. Acá solo pedimos qué servicio se va a
 * reservar, con qué suscripción se paga y cuándo.</p>
 */
public record CreateBookingRequest(
        @NotNull UUID serviceId,
        @NotNull UUID subscriptionId,
        UUID staffMemberId,
        @NotNull @FutureOrPresent @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDateTime fechaHoraInicio,
        @Size(max = 500) String notas) {
}

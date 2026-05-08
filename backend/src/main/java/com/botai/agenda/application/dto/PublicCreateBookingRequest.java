package com.botai.agenda.application.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Payload para que un cliente solicite un turno desde la vista pública.
 *
 * <p>No requiere suscripción: crea una reserva en estado {@code PENDING}.</p>
 */
public record PublicCreateBookingRequest(
        @NotNull UUID serviceId,
        UUID staffMemberId,
        @NotNull @FutureOrPresent @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDateTime fechaHoraInicio,
        @NotBlank @Size(max = 120) String nombreCliente,
        @Email @Size(max = 200) String emailCliente,
        @Size(max = 32) String telefonoCliente,
        @Size(max = 500) String notas
) {
}


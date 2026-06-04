package com.botai.application.agenda.dto;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Payload para que un cliente solicite un turno desde la vista pública.
 *
 * <p>Requiere sesión OTP ({@code X-Agenda-Client-Session}) salvo {@code clientId} legacy.</p>
 */
public record PublicCreateBookingRequest(
        @NotNull UUID serviceId,
        UUID staffMemberId,
        @NotNull @FutureOrPresent @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDateTime fechaHoraInicio,
        UUID clientId,
        @Size(max = 120) String nombreCliente,
        @Email @Size(max = 200) String emailCliente,
        @Size(max = 32) String telefonoCliente,
        @Size(max = 500) String notas
) {}

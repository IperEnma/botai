package com.botai.application.agenda.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Reserva PENDING creada por el panel del tenant (staff), sin OTP público.
 */
public record TenantCreatePendingBookingRequest(
        @NotNull UUID clientId,
        @NotNull UUID serviceId,
        UUID staffMemberId,
        @NotNull @FutureOrPresent @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDateTime fechaHoraInicio,
        @Size(max = 500) String notas
) {
}

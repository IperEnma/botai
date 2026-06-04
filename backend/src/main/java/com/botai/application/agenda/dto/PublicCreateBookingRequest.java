package com.botai.application.agenda.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.FutureOrPresent;
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
        UUID clientId,
        @Size(max = 120) String nombreCliente,
        @Email @Size(max = 200) String emailCliente,
        @Size(max = 32) String telefonoCliente,
        @Size(max = 500) String notas,
        /** Token emitido por POST .../phone-verification/verify (obligatorio sin clientId si verification enabled). */
        @Size(max = 64) String phoneVerificationToken
) {

    @AssertTrue(message = "Nombre obligatorio al reservar sin cliente existente")
    public boolean isNombrePresentWhenNoClientId() {
        if (clientId != null) {
            return true;
        }
        return nombreCliente != null && !nombreCliente.isBlank();
    }

    @AssertTrue(message = "Teléfono obligatorio (mínimo 7 dígitos) al reservar sin cliente existente")
    public boolean isTelefonoPresentWhenNoClientId() {
        if (clientId != null) {
            return true;
        }
        return AgendaPhoneNormalizer.isValid(telefonoCliente);
    }
}


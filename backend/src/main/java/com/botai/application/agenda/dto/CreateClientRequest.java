package com.botai.application.agenda.dto;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateClientRequest(
        @NotBlank @Size(max = 120) String nombre,
        @Email @Size(max = 200) String email,
        @NotBlank @Size(max = 32) String telefono
) {

    @AssertTrue(message = "Teléfono obligatorio (mínimo 7 dígitos)")
    public boolean isTelefonoValid() {
        return AgendaPhoneNormalizer.isValid(telefono);
    }
}

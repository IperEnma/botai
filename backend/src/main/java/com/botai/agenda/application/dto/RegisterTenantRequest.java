package com.botai.agenda.application.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request de registro público de un nuevo tenant en AGENDA.
 */
public record RegisterTenantRequest(

        @NotBlank
        @Size(min = 2, max = 255)
        String nombrePropietario,

        @NotBlank
        @Email
        String email,

        @Size(max = 32)
        String telefono,

        @NotBlank
        @Size(min = 2, max = 255)
        String nombreNegocio,

        String categoriaSlug
) {
}

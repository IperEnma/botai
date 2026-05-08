package com.botai.application.agenda.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request de registro público de un nuevo tenant en AGENDA.
 * <p>Indicar exactamente uno: {@code email} (correo real) o {@code numero} (solo dígitos del teléfono, canal WhatsApp).</p>
 */
public record RegisterTenantRequest(

        @NotBlank
        @Size(min = 2, max = 255)
        String nombrePropietario,

        /** Correo cuando el alta es por email; null si se usa {@link #numero}. */
        @Size(max = 255)
        @Email
        String email,

        /** Solo dígitos cuando el alta es por WhatsApp; null si se usa {@link #email}. */
        @Size(max = 32)
        String numero,

        @Size(max = 32)
        String telefono,

        @NotBlank
        @Size(min = 2, max = 255)
        String nombreNegocio,

        String categoriaSlug
) {
    /** Normaliza cadenas vacías a {@code null} para validación ({@code @Email} ignora null). */
    public RegisterTenantRequest {
        email = (email == null || email.isBlank()) ? null : email;
        numero = (numero == null || numero.isBlank()) ? null : numero;
        telefono = (telefono == null || telefono.isBlank()) ? null : telefono;
        categoriaSlug = (categoriaSlug == null || categoriaSlug.isBlank()) ? null : categoriaSlug;
    }
}

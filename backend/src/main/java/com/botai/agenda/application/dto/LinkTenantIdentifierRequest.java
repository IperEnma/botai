package com.botai.agenda.application.dto;

import jakarta.validation.constraints.Email;

/**
 * Request de {@code POST /api/agenda/me/tenant-admin/identifiers}.
 *
 * Indicar exactamente uno: {@code email} o {@code numero} (solo dígitos).
 */
public record LinkTenantIdentifierRequest(
        @Email(message = "email inválido")
        String email,
        String numero
) {
    public LinkTenantIdentifierRequest {
        email = email == null || email.isBlank() ? null : email.strip();
        numero = numero == null || numero.isBlank() ? null : numero.strip();
    }
}


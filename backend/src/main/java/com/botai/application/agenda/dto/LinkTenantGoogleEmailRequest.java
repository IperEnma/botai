package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Cuerpo de {@code POST /api/agenda/me/tenant-admin/link}.
 */
public record LinkTenantGoogleEmailRequest(
        @NotBlank String accessCode
) {}

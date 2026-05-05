package com.botai.agenda.application.dto;

import java.util.UUID;

/**
 * Respuesta del endpoint de registro público de tenant.
 */
public record RegisterTenantResponse(
        String tenantId,
        UUID businessId,
        String accessCode
) {
}

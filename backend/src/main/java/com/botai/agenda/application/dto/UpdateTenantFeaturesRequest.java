package com.botai.agenda.application.dto;

/**
 * Request tipo PATCH para actualizar los flags de un tenant. Todos los campos
 * son nullables: solo los no-nulos se aplican sobre la config existente.
 */
public record UpdateTenantFeaturesRequest(
        Boolean agendaEnabled,
        Boolean publicSearchEnabled,
        Boolean loyaltyEngineEnabled,
        Boolean autoNotifications
) {
}

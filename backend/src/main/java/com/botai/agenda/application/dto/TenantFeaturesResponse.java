package com.botai.agenda.application.dto;

public record TenantFeaturesResponse(
        boolean agendaEnabled,
        boolean publicSearchEnabled,
        boolean loyaltyEngineEnabled,
        boolean autoNotifications
) {
}

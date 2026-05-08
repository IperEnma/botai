package com.botai.application.agenda.dto;

public record TenantFeaturesResponse(
        boolean agendaEnabled,
        boolean publicSearchEnabled,
        boolean loyaltyEngineEnabled,
        boolean autoNotifications
) {
}

package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.TenantFeaturesResponse;
import com.botai.domain.agenda.model.TenantConfig;

public final class TenantConfigDtoMapper {

    private TenantConfigDtoMapper() {
    }

    public static TenantFeaturesResponse toResponse(TenantConfig config) {
        if (config == null) {
            return null;
        }
        return new TenantFeaturesResponse(
                config.isAgendaEnabled(),
                config.isPublicSearchEnabled(),
                config.isLoyaltyEngineEnabled(),
                config.isAutoNotifications()
        );
    }
}

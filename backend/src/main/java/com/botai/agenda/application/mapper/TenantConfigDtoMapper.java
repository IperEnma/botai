package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.TenantFeaturesResponse;
import com.botai.agenda.domain.model.TenantConfig;

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

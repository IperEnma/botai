package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.infrastructure.persistence.entity.TenantConfigEntity;

public final class TenantConfigMapper {

    private TenantConfigMapper() {
    }

    public static TenantConfig toDomain(TenantConfigEntity entity) {
        if (entity == null) {
            return null;
        }
        return new TenantConfig(
                entity.getTenantId(),
                entity.isAgendaEnabled(),
                entity.isPublicSearchEnabled(),
                entity.isLoyaltyEngineEnabled(),
                entity.isAutoNotifications()
        );
    }

    public static TenantConfigEntity toEntity(TenantConfig config) {
        if (config == null) {
            return null;
        }
        TenantConfigEntity entity = new TenantConfigEntity();
        entity.setTenantId(config.getTenantId());
        entity.setAgendaEnabled(config.isAgendaEnabled());
        entity.setPublicSearchEnabled(config.isPublicSearchEnabled());
        entity.setLoyaltyEngineEnabled(config.isLoyaltyEngineEnabled());
        entity.setAutoNotifications(config.isAutoNotifications());
        return entity;
    }
}

package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.infrastructure.agenda.persistence.entity.BusinessSettingsEntity;

public final class BusinessSettingsMapper {

    private BusinessSettingsMapper() {
    }

    public static BusinessSettings toDomain(BusinessSettingsEntity entity) {
        if (entity == null) {
            return null;
        }
        return new BusinessSettings(
                entity.getBusinessId(),
                entity.getHoursCancellationLimit(),
                entity.getLoyaltyMinAttendances(),
                entity.getLoyaltyWindowDays(),
                entity.getExpirationAlertDays(),
                entity.getExpirationAlertCredits(),
                entity.isAutoNotifyEnabled()
        );
    }

    public static BusinessSettingsEntity toEntity(BusinessSettings settings) {
        if (settings == null) {
            return null;
        }
        BusinessSettingsEntity entity = new BusinessSettingsEntity();
        entity.setBusinessId(settings.getBusinessId());
        entity.setHoursCancellationLimit(settings.getHoursCancellationLimit());
        entity.setLoyaltyMinAttendances(settings.getLoyaltyMinAttendances());
        entity.setLoyaltyWindowDays(settings.getLoyaltyWindowDays());
        entity.setExpirationAlertDays(settings.getExpirationAlertDays());
        entity.setExpirationAlertCredits(settings.getExpirationAlertCredits());
        entity.setAutoNotifyEnabled(settings.isAutoNotifyEnabled());
        return entity;
    }
}

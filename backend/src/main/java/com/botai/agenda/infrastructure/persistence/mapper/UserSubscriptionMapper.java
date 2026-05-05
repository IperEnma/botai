package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.UserSubscription;
import com.botai.agenda.infrastructure.persistence.entity.UserSubscriptionEntity;

public final class UserSubscriptionMapper {

    private UserSubscriptionMapper() {
    }

    public static UserSubscription toDomain(UserSubscriptionEntity entity) {
        if (entity == null) {
            return null;
        }
        return new UserSubscription(
                entity.getId(),
                entity.getUserId(),
                entity.getPlanId(),
                entity.getBusinessId(),
                entity.getSaldoActual(),
                entity.getFechaInicio(),
                entity.getFechaExpiracion(),
                entity.getEstado(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static UserSubscriptionEntity toEntity(UserSubscription subscription) {
        if (subscription == null) {
            return null;
        }
        UserSubscriptionEntity entity = new UserSubscriptionEntity();
        entity.setId(subscription.getId());
        entity.setUserId(subscription.getUserId());
        entity.setPlanId(subscription.getPlanId());
        entity.setBusinessId(subscription.getBusinessId());
        entity.setSaldoActual(subscription.getSaldoActual());
        entity.setFechaInicio(subscription.getFechaInicio());
        entity.setFechaExpiracion(subscription.getFechaExpiracion());
        entity.setEstado(subscription.getEstado());
        entity.setCreatedAt(subscription.getCreatedAt());
        entity.setUpdatedAt(subscription.getUpdatedAt());
        return entity;
    }
}

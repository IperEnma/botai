package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.Notification;
import com.botai.infrastructure.agenda.persistence.entity.NotificationEntity;

public final class NotificationMapper {

    private NotificationMapper() {}

    public static NotificationEntity toEntity(Notification domain) {
        NotificationEntity e = new NotificationEntity();
        e.setId(domain.getId());
        e.setBusinessId(domain.getBusinessId());
        e.setUserId(domain.getUserId());
        e.setCanal(domain.getCanal());
        e.setTitulo(domain.getTitulo());
        e.setCuerpo(domain.getCuerpo());
        e.setEstado(domain.getEstado());
        return e;
    }

    public static Notification toDomain(NotificationEntity e) {
        return new Notification(
                e.getId(), e.getBusinessId(), e.getUserId(),
                e.getCanal(), e.getTitulo(), e.getCuerpo(), e.getEstado(),
                e.getCreatedAt(), e.getUpdatedAt()
        );
    }
}

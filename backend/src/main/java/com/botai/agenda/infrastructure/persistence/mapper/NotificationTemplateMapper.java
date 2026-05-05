package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.NotificationTemplate;
import com.botai.agenda.infrastructure.persistence.entity.NotificationTemplateEntity;

public final class NotificationTemplateMapper {

    private NotificationTemplateMapper() {}

    public static NotificationTemplateEntity toEntity(NotificationTemplate domain) {
        NotificationTemplateEntity e = new NotificationTemplateEntity();
        e.setId(domain.getId());
        e.setBusinessId(domain.getBusinessId());
        e.setCodigo(domain.getCodigo());
        e.setCanal(domain.getCanal());
        e.setTitulo(domain.getTitulo());
        e.setCuerpo(domain.getCuerpo());
        return e;
    }

    public static NotificationTemplate toDomain(NotificationTemplateEntity e) {
        return new NotificationTemplate(
                e.getId(), e.getBusinessId(), e.getCodigo(), e.getCanal(),
                e.getTitulo(), e.getCuerpo(), e.getCreatedAt(), e.getUpdatedAt()
        );
    }
}

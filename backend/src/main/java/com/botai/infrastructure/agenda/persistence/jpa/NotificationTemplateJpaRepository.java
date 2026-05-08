package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.infrastructure.agenda.persistence.entity.NotificationTemplateEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface NotificationTemplateJpaRepository
        extends JpaRepository<NotificationTemplateEntity, UUID> {

    Optional<NotificationTemplateEntity> findByBusinessIdAndCodigoAndCanal(
            UUID businessId, String codigo, NotificationCanal canal);

    List<NotificationTemplateEntity> findAllByBusinessId(UUID businessId);
}

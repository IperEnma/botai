package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.NotificationEstado;
import com.botai.agenda.infrastructure.persistence.entity.NotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, UUID> {

    List<NotificationEntity> findAllByUserId(UUID userId);

    List<NotificationEntity> findAllByUserIdAndEstado(UUID userId, NotificationEstado estado);
}

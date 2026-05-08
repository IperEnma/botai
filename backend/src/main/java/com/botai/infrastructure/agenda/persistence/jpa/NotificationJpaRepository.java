package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.NotificationEstado;
import com.botai.infrastructure.agenda.persistence.entity.NotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, UUID> {

    List<NotificationEntity> findAllByUserId(UUID userId);

    List<NotificationEntity> findAllByUserIdAndEstado(UUID userId, NotificationEstado estado);
}

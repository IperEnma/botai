package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.Notification;
import com.botai.domain.agenda.model.NotificationEstado;
import com.botai.domain.agenda.repository.NotificationRepository;
import com.botai.infrastructure.agenda.persistence.mapper.NotificationMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class JpaNotificationRepository implements NotificationRepository {

    private final NotificationJpaRepository jpa;

    public JpaNotificationRepository(NotificationJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Notification save(Notification notification) {
        var entity = NotificationMapper.toEntity(notification);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        return NotificationMapper.toDomain(jpa.save(entity));
    }

    @Override
    public List<Notification> findAllByUserId(UUID userId) {
        return jpa.findAllByUserId(userId).stream()
                .map(NotificationMapper::toDomain)
                .toList();
    }

    @Override
    public List<Notification> findAllByUserIdAndEstado(UUID userId, NotificationEstado estado) {
        return jpa.findAllByUserIdAndEstado(userId, estado).stream()
                .map(NotificationMapper::toDomain)
                .toList();
    }
}

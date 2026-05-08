package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.Notification;
import com.botai.domain.agenda.model.NotificationEstado;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository {

    Notification save(Notification notification);

    List<Notification> findAllByUserId(UUID userId);

    List<Notification> findAllByUserIdAndEstado(UUID userId, NotificationEstado estado);
}

package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.Notification;
import com.botai.agenda.domain.model.NotificationEstado;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository {

    Notification save(Notification notification);

    List<Notification> findAllByUserId(UUID userId);

    List<Notification> findAllByUserIdAndEstado(UUID userId, NotificationEstado estado);
}

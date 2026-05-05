package com.botai.agenda.infrastructure.notification;

import com.botai.agenda.domain.model.Notification;
import com.botai.agenda.domain.model.NotificationCanal;
import com.botai.agenda.domain.model.NotificationEstado;
import com.botai.agenda.domain.notification.NotificationPort;
import com.botai.agenda.domain.repository.NotificationRepository;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Implementación in-app de {@link NotificationPort}.
 * Persiste la notificación en {@code agenda_notifications} con estado SENT.
 * EMAIL y PUSH quedan stubbed para fases futuras.
 */
@Component
public class InAppNotificationAdapter implements NotificationPort {

    private final NotificationRepository notificationRepository;

    public InAppNotificationAdapter(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Override
    public void send(UUID businessId, UUID userId, String titulo, String cuerpo,
                     NotificationCanal canal) {
        Notification notification = new Notification(
                null, businessId, userId, canal,
                titulo, cuerpo, NotificationEstado.SENT,
                null, null
        );
        notificationRepository.save(notification);
    }
}

package com.botai.infrastructure.agenda.notification;

import com.botai.domain.agenda.model.Notification;
import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationEstado;
import com.botai.domain.agenda.notification.NotificationPort;
import com.botai.domain.agenda.repository.NotificationRepository;
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

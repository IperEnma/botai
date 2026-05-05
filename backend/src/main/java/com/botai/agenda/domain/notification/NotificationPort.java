package com.botai.agenda.domain.notification;

import com.botai.agenda.domain.model.NotificationCanal;

import java.util.UUID;

/**
 * Puerto de salida para envío de notificaciones.
 *
 * <p>La implementación in-app persiste la notificación en
 * {@code agenda_notifications}. Las implementaciones EMAIL y PUSH están
 * stubbed para fases futuras.</p>
 */
public interface NotificationPort {

    void send(UUID businessId, UUID userId, String titulo, String cuerpo, NotificationCanal canal);
}

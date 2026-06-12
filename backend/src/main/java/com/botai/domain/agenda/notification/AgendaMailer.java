package com.botai.domain.agenda.notification;

/**
 * Puerto de salida para envío de mails transaccionales del módulo Agenda
 * (invitaciones de equipo, bienvenida a admins, etc.).
 *
 * <p>El cuerpo se entrega ya renderizado en HTML por el caller. La elección de
 * provider (log / Resend / SMTP) vive en infraestructura vía {@code mail.provider}.</p>
 */
public interface AgendaMailer {

    void send(MailMessage message);

    record MailMessage(String to, String subject, String htmlBody) {
        public MailMessage {
            if (to == null || to.isBlank()) {
                throw new IllegalArgumentException("to no puede ser nulo ni vacío");
            }
            if (subject == null || subject.isBlank()) {
                throw new IllegalArgumentException("subject no puede ser nulo ni vacío");
            }
            if (htmlBody == null || htmlBody.isBlank()) {
                throw new IllegalArgumentException("htmlBody no puede ser nulo ni vacío");
            }
        }
    }
}

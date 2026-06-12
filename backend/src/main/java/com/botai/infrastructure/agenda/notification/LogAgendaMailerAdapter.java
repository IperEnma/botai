package com.botai.infrastructure.agenda.notification;

import com.botai.domain.agenda.notification.AgendaMailer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Adapter por defecto: solo loguea el mail. Útil para dev/CI sin credenciales.
 * Activado cuando {@code mail.provider=log} (default).
 */
@Component
@ConditionalOnProperty(name = "mail.provider", havingValue = "log", matchIfMissing = true)
public class LogAgendaMailerAdapter implements AgendaMailer {

    private static final Logger log = LoggerFactory.getLogger(LogAgendaMailerAdapter.class);

    @Override
    public void send(MailMessage message) {
        log.info("[MAIL-LOG] to={} subject=\"{}\"\n{}",
                message.to(), message.subject(), message.htmlBody());
    }
}

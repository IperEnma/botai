package com.botai.infrastructure.agenda.notification;

import com.botai.domain.agenda.notification.AgendaMailer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Adapter para Resend (https://resend.com) vía su REST API.
 * Activado cuando {@code mail.provider=resend}.
 */
@Component
@ConditionalOnProperty(name = "mail.provider", havingValue = "resend")
public class ResendAgendaMailerAdapter implements AgendaMailer {

    private static final Logger log = LoggerFactory.getLogger(ResendAgendaMailerAdapter.class);

    private final MailProperties props;
    private final RestClient http;

    public ResendAgendaMailerAdapter(MailProperties props) {
        this.props = props;
        if (props.getResend().getApiKey() == null || props.getResend().getApiKey().isBlank()) {
            throw new IllegalStateException(
                    "mail.provider=resend pero RESEND_API_KEY no está configurada");
        }
        this.http = RestClient.builder()
                .baseUrl(props.getResend().getApiUrl())
                .defaultHeader("Authorization", "Bearer " + props.getResend().getApiKey())
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Override
    public void send(MailMessage message) {
        String fromName = props.getFromName();
        String fromAddress = props.getFrom();
        String from = (fromName != null && !fromName.isBlank())
                ? fromName + " <" + fromAddress + ">"
                : fromAddress;

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("from", from);
        payload.put("to", List.of(message.to()));
        payload.put("subject", message.subject());
        payload.put("html", message.htmlBody());

        try {
            http.post()
                    .body(payload)
                    .retrieve()
                    .toBodilessEntity();
            log.info("[MAIL-RESEND] enviado to={} subject=\"{}\"",
                    message.to(), message.subject());
        } catch (RestClientResponseException e) {
            log.warn("[MAIL-RESEND] fallo to={} status={} body={}",
                    message.to(), e.getStatusCode(), e.getResponseBodyAsString());
            throw e;
        }
    }
}

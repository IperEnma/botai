package com.botai.infrastructure.agenda.notification;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Config del envío de mail de Agenda. Mapea {@code mail.*} en application.yml.
 */
@Component
@ConfigurationProperties(prefix = "mail")
public class MailProperties {

    /** {@code log} (default) o {@code resend}. */
    private String provider = "log";
    /** Dirección remitente. */
    private String from = "onboarding@resend.dev";
    /** Nombre legible del remitente. */
    private String fromName = "Botai Agenda";
    /** Ruta del frontend para el botón "Ingresar". */
    private String loginPath = "/login";

    private final Resend resend = new Resend();

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getFrom() { return from; }
    public void setFrom(String from) { this.from = from; }

    public String getFromName() { return fromName; }
    public void setFromName(String fromName) { this.fromName = fromName; }

    public String getLoginPath() { return loginPath; }
    public void setLoginPath(String loginPath) { this.loginPath = loginPath; }

    public Resend getResend() { return resend; }

    public static class Resend {
        private String apiUrl = "https://api.resend.com/emails";
        private String apiKey = "";

        public String getApiUrl() { return apiUrl; }
        public void setApiUrl(String apiUrl) { this.apiUrl = apiUrl; }

        public String getApiKey() { return apiKey; }
        public void setApiKey(String apiKey) { this.apiKey = apiKey; }
    }
}

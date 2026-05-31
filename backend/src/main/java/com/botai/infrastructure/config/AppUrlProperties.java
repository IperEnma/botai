package com.botai.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * URLs públicas de la app (un solo backend + frontend web).
 * Valores: {@code urls.backend} y {@code urls.frontend} en application.yml.
 * Uploads y webhooks se derivan del backend; links de agenda usan el frontend.
 */
@Component
@ConfigurationProperties(prefix = "urls")
public class AppUrlProperties {

    private static final String WHATSAPP_WEBHOOK_PATH = "/api/v1/webhook/whatsapp";
    private static final String UPLOADS_PATH = "/uploads";

    /** Valores inyectados desde application.yml → urls.* */
    private String backend;
    private String frontend;

    public String getBackend() {
        return backend;
    }

    public void setBackend(String backend) {
        this.backend = backend;
    }

    public String getFrontend() {
        return frontend;
    }

    public void setFrontend(String frontend) {
        this.frontend = frontend;
    }

    /** Backend sin barra final. */
    public String normalizedBackend() {
        return stripTrailingSlashes(backend == null ? "" : backend.strip());
    }

    /** Frontend sin barra final. */
    public String normalizedFrontend() {
        return stripTrailingSlashes(frontend == null ? "" : frontend.strip());
    }

    public String uploadsBaseUrl() {
        return normalizedBackend() + UPLOADS_PATH;
    }

    public String whatsappWebhookUrl() {
        return normalizedBackend() + WHATSAPP_WEBHOOK_PATH;
    }

    private static String stripTrailingSlashes(String value) {
        String v = value;
        while (v.endsWith("/")) {
            v = v.substring(0, v.length() - 1);
        }
        return v;
    }
}

package com.botai.infrastructure.chatbot.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuración global del webhook WhatsApp Cloud API.
 */
@Component
@ConfigurationProperties(prefix = "bot.whatsapp")
public class BotWhatsAppConfig {

    /**
     * Secreto del servidor para derivar verify tokens (no se guarda el token en BD).
     */
    private String verifySecret = "dev-insecure-change-me";

    /** Clave para cifrar access tokens en BD (AES-256-GCM). */
    private String encryptionSecret = "dev-insecure-change-me";

    /**
     * Fallback opcional legacy (single-tenant). Preferir verify-secret + token derivado por bot.
     */
    private String verifyToken = "";

    /** URL pública del backend (sin path), p. ej. https://api.tudominio.com */
    private String publicBaseUrl = "http://localhost:8080";

    public String getVerifyToken() {
        return verifyToken;
    }

    public void setVerifyToken(String verifyToken) {
        this.verifyToken = verifyToken;
    }

    public String getVerifySecret() {
        return verifySecret;
    }

    public void setVerifySecret(String verifySecret) {
        this.verifySecret = verifySecret;
    }

    public String getEncryptionSecret() {
        return encryptionSecret;
    }

    public void setEncryptionSecret(String encryptionSecret) {
        this.encryptionSecret = encryptionSecret;
    }

    public String getPublicBaseUrl() {
        return publicBaseUrl;
    }

    public void setPublicBaseUrl(String publicBaseUrl) {
        this.publicBaseUrl = publicBaseUrl;
    }

    public String webhookUrl() {
        String base = publicBaseUrl == null ? "" : publicBaseUrl.strip();
        while (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base + "/api/v1/webhook/whatsapp";
    }
}

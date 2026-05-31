package com.botai.infrastructure.chatbot.config;

import com.botai.infrastructure.config.AppUrlProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuración global del webhook WhatsApp Cloud API.
 */
@Component
@ConfigurationProperties(prefix = "bot.whatsapp")
public class BotWhatsAppConfig {

    private final AppUrlProperties appUrls;

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

    public BotWhatsAppConfig(AppUrlProperties appUrls) {
        this.appUrls = appUrls;
    }

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

    public String webhookUrl() {
        return appUrls.whatsappWebhookUrl();
    }
}

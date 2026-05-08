package com.botai.infrastructure.chatbot.channel.whatsapp;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuración para WhatsApp Cloud API (Meta).
 * Obtener verify_token, access_token y phone_number_id desde Meta for Developers.
 */
@ConfigurationProperties(prefix = "bot.channels.whatsapp")
public class WhatsAppProperties {

    /**
     * Token que Meta envía en GET (hub.verify_token); debe coincidir con el que configuras en el webhook.
     */
    private String verifyToken = "";
    /**
     * Token de acceso permanente (System User) o temporal. Necesario para enviar mensajes.
     */
    private String accessToken = "";
    /**
     * ID del número de teléfono de negocio (Phone Number ID) en Meta. Necesario para enviar mensajes.
     */
    private String phoneNumberId = "";

    public String getVerifyToken() {
        return verifyToken;
    }

    public void setVerifyToken(String verifyToken) {
        this.verifyToken = verifyToken != null ? verifyToken : "";
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken != null ? accessToken : "";
    }

    public String getPhoneNumberId() {
        return phoneNumberId;
    }

    public void setPhoneNumberId(String phoneNumberId) {
        this.phoneNumberId = phoneNumberId != null ? phoneNumberId : "";
    }

    public boolean isConfigured() {
        return accessToken != null && !accessToken.isBlank()
            && phoneNumberId != null && !phoneNumberId.isBlank();
    }
}

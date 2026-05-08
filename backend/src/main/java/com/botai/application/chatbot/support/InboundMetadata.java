package com.botai.application.chatbot.support;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.InboundMessage;

import java.util.Map;

/**
 * Claves y lectura de metadatos comunes en mensajes entrantes (canal-agnóstico).
 */
public final class InboundMetadata {

    public static final String TENANT_ID = ConversationContextKeys.TENANT_ID;
    /** Nombre para mostrar del perfil WhatsApp (Cloud API {@code contacts[].profile.name}), si viene en el webhook. */
    public static final String WHATSAPP_PROFILE_NAME = "whatsappProfileName";

    private InboundMetadata() {}

    /** {@code tenantId} normalizado o {@code null} si falta o está vacío. */
    public static String tenantId(InboundMessage inbound) {
        if (inbound == null || inbound.getMetadata() == null) {
            return null;
        }
        return tenantId(inbound.getMetadata());
    }

    /** Útil cuando el mapa viene del adaptador sin {@link InboundMessage} completo. */
    public static String tenantId(Map<String, Object> metadata) {
        if (metadata == null) {
            return null;
        }
        Object t = metadata.get(TENANT_ID);
        if (t == null) {
            return null;
        }
        String s = t.toString().strip();
        return s.isEmpty() ? null : s;
    }

    /** Nombre de perfil WhatsApp o {@code null}. Solo informativo; no sustituye nombre escrito por el usuario salvo reglas explícitas (p. ej. fast path). */
    public static String whatsappProfileName(InboundMessage inbound) {
        if (inbound == null || inbound.getMetadata() == null) {
            return null;
        }
        Object n = inbound.getMetadata().get(WHATSAPP_PROFILE_NAME);
        if (n == null) {
            return null;
        }
        String s = n.toString().strip();
        return s.isEmpty() ? null : s;
    }
}

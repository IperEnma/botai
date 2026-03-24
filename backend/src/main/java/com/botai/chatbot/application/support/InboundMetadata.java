package com.botai.chatbot.application.support;

import com.botai.chatbot.domain.ConversationContextKeys;
import com.botai.chatbot.domain.model.InboundMessage;

import java.util.Map;

/**
 * Claves y lectura de metadatos comunes en mensajes entrantes (canal-agnóstico).
 */
public final class InboundMetadata {

    public static final String TENANT_ID = ConversationContextKeys.TENANT_ID;

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
}

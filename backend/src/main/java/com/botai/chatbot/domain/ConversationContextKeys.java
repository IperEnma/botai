package com.botai.chatbot.domain;

/**
 * Claves estándar del mapa de contexto de conversación (persistido y en memoria).
 */
public final class ConversationContextKeys {

    public static final String TENANT_ID = "tenantId";
    public static final String CURRENT_MENU = "currentMenu";
    /** Wizard de citas (legado); puede quedar basura si se confundió un saludo con datos. */
    public static final String CUSTOMER_DOCUMENT = "customerDocument";
    public static final String CUSTOMER_NAME = "customerName";

    private ConversationContextKeys() {}
}

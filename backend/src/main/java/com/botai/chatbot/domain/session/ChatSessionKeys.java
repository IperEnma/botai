package com.botai.chatbot.domain.session;

/**
 * Claves del contexto de conversación para sesiones de chat (historial acotado para el LLM).
 */
public final class ChatSessionKeys {

    public static final String SESSION_ID = "chatSessionId";
    public static final String SESSION_LAST_ACTIVITY = "chatSessionLastActivityAt";

    private ChatSessionKeys() {}
}

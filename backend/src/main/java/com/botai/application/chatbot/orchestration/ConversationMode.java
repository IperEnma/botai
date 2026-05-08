package com.botai.application.chatbot.orchestration;

/**
 * Modo conversacional del tenant según feature flags (FAQ / IA).
 * Cada valor tiene un {@link ConversationModeHandler} asociado (Strategy).
 */
public enum ConversationMode {
    /** Solo menú + FAQ. */
    FAQ_ONLY,
    /** Solo IA (RAG + tools). */
    AI_ONLY,
    /** Primero FAQ; si no hay match, IA. */
    FAQ_AND_AI,
    /** Ninguna capa activa → el router aplicará fallback (p. ej. no_match). */
    NONE
}

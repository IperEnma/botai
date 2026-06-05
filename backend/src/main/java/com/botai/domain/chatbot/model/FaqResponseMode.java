package com.botai.domain.chatbot.model;

/**
 * Modo de respuesta FAQ: texto fijo al usuario o pista inyectada al contexto RAG (el LLM parafrasea).
 */
public enum FaqResponseMode {
    FIXED,
    RAG_HINT;

    public static FaqResponseMode fromDb(String raw) {
        if (raw == null || raw.isBlank()) {
            return FIXED;
        }
        try {
            return valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return FIXED;
        }
    }
}

package com.botai.infrastructure.chatbot.booking;

import java.util.Locale;

/**
 * Normaliza cédula/documento para guardar y buscar de forma consistente (sin puntos, guiones ni espacios).
 */
public final class CustomerDocumentNormalizer {

    private CustomerDocumentNormalizer() {}

    public static String normalize(String document) {
        if (document == null) return "";
        return document.strip().toUpperCase(Locale.ROOT).replaceAll("[^0-9A-Z]", "");
    }

    public static boolean isMissing(String document) {
        return normalize(document).isEmpty();
    }
}

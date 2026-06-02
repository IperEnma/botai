package com.botai.application.agenda.support;

/**
 * Normalización única de teléfonos para reservas públicas/privadas y consulta por WhatsApp.
 */
public final class AgendaPhoneNormalizer {

    private AgendaPhoneNormalizer() {}

    public static String normalize(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replaceAll("[^0-9+]", "");
    }

    public static boolean isValid(String raw) {
        return normalize(raw).length() >= 7;
    }
}

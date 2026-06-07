package com.botai.application.agenda.support;

import java.util.regex.Pattern;

/**
 * Validación de texto libre para {@code agenda_businesses.direccion}.
 * Acepta dirección exacta, barrio o ciudad; rechaza URLs y paths de media.
 */
public final class BusinessAddressSupport {

    private static final Pattern HTTP = Pattern.compile("^https?://", Pattern.CASE_INSENSITIVE);
    private static final Pattern HAS_LETTER = Pattern.compile("\\p{L}");

    private BusinessAddressSupport() {}

    /** {@code null} o blanco → {@code null}; texto válido → trim; inválido → excepción. */
    public static String normalizeOrNull(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String trimmed = raw.trim();
        validateFormat(trimmed);
        return trimmed;
    }

    public static void validateFormat(String value) {
        String message = formatErrorMessage(value);
        if (message != null) {
            throw new IllegalArgumentException(message);
        }
    }

    /** Mensaje de error en español, o {@code null} si el formato es aceptable. */
    public static String formatErrorMessage(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String v = raw.trim();
        if (v.length() < 3) {
            return "La dirección es demasiado corta.";
        }
        if (HTTP.matcher(v).find() || v.contains("/uploads/")) {
            return "La dirección no puede ser una URL ni un enlace de archivo.";
        }
        if (!HAS_LETTER.matcher(v).find()) {
            return "La dirección debe incluir al menos una letra (ej. calle, barrio o ciudad).";
        }
        return null;
    }
}

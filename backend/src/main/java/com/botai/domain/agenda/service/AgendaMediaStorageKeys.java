package com.botai.domain.agenda.service;

import java.util.Locale;

/**
 * Normalización de claves y URLs públicas para uploads de Agenda.
 */
public final class AgendaMediaStorageKeys {

    private AgendaMediaStorageKeys() {}

    public static String normalize(String relativePath) {
        String p = relativePath.replace('\\', '/');
        while (p.startsWith("/")) {
            p = p.substring(1);
        }
        if (p.startsWith("uploads/")) {
            p = p.substring("uploads/".length());
        }
        return p;
    }

    public static String publicUrl(String storageKey) {
        return "/uploads/" + normalize(storageKey);
    }

    public static String contentTypeFromPath(String storageKey) {
        String lower = normalize(storageKey).toLowerCase(Locale.ROOT);
        if (lower.endsWith(".png")) {
            return "image/png";
        }
        if (lower.endsWith(".webp")) {
            return "image/webp";
        }
        if (lower.endsWith(".gif")) {
            return "image/gif";
        }
        return "image/jpeg";
    }
}

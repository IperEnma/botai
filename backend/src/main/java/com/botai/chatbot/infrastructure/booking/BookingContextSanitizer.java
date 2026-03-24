package com.botai.chatbot.infrastructure.booking;

/**
 * Detecta nombre/documento guardados en el contexto de conversación que no son datos reales del cliente
 * (p. ej. el saludo "Hola" mal interpretado como cédula en un wizard antiguo).
 */
public final class BookingContextSanitizer {

    private BookingContextSanitizer() {}

    /** Misma semántica que el placeholder de documento en agendamiento/cancelación. */
    public static boolean isPlaceholderDocument(String doc) {
        if (doc == null || doc.isBlank()) {
            return true;
        }
        String d = ServiceNameMatcher.normalizeKey(doc);
        return d.equals("por confirmar") || d.equals("n/a") || d.equals("pendiente")
            || d.equals("hola");
    }

    /** Misma semántica que el placeholder de nombre en agendamiento. */
    public static boolean isPlaceholderName(String name) {
        if (name == null || name.isBlank()) {
            return true;
        }
        String n = ServiceNameMatcher.normalizeKey(name);
        return n.equals("cliente whatsapp") || n.equals("por confirmar") || n.equals("n/a")
            || n.equals("cliente")
            || n.equals("hola") || n.equals("hi") || n.equals("hey") || n.equals("hello");
    }
}

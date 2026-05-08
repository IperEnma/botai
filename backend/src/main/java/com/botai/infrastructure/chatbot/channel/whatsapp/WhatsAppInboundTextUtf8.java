package com.botai.infrastructure.chatbot.channel.whatsapp;

import java.nio.charset.StandardCharsets;

/**
 * Corrige texto UTF-8 interpretado por error como secuencia Latin-1/ISO-8859-1 (mojibake tipo "Â¿" en lugar de "¿", "Ã±" en lugar de "ñ").
 * Se usa en texto entrante (webhook) y saliente (respuestas hacia Meta) cuando el LLM o capas intermedias dejan secuencias de bytes UTF-8 como varios caracteres U+00xx.
 * <p>
 * Estrategia: si todos los caracteres están en el rango Latin-1 (≤ U+00FF), se reempaquetan los bytes ISO-8859-1 y se decodifican como UTF-8. Si el resultado contiene U+FFFD o parece inválido, se devuelve el original (así no se rompe texto ya correcto con letras como é/ñ en un solo codepoint).
 */
public final class WhatsAppInboundTextUtf8 {

    private static final int MAX_PASSES = 4;

    private WhatsAppInboundTextUtf8() {}

    /**
     * Intenta corregir mojibake UTF-8/Latin-1; si no aplica o no mejora, devuelve el original.
     */
    public static String tryFix(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        if (!allCharsInLatin1Range(text)) {
            return text;
        }
        String current = text;
        for (int pass = 0; pass < MAX_PASSES; pass++) {
            String next = tryFixLatin1BytesAsUtf8Once(current);
            if (next.equals(current)) {
                break;
            }
            current = next;
            // Tras una pasada correcta puede quedar Unicode fuera de Latin-1 (comillas tipográficas, etc.): no más roundtrips.
            if (!allCharsInLatin1Range(current)) {
                break;
            }
        }
        return current;
    }

    private static boolean allCharsInLatin1Range(String s) {
        return s.chars().allMatch(cp -> cp <= 0xFF);
    }

    private static String tryFixLatin1BytesAsUtf8Once(String text) {
        try {
            byte[] bytes = text.getBytes(StandardCharsets.ISO_8859_1);
            String fixed = new String(bytes, StandardCharsets.UTF_8);
            if (fixed.contains("\uFFFD")) {
                return text;
            }
            if (fixed.isBlank() && !text.isBlank()) {
                return text;
            }
            // Evitar sustituir por algo claramente erróneo
            if (fixed.length() < text.length() / 2 && text.length() > 3) {
                return text;
            }
            return fixed;
        } catch (Exception e) {
            return text;
        }
    }
}

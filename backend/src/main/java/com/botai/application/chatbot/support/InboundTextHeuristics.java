package com.botai.application.chatbot.support;

/**
 * Heurísticas sobre texto entrante (encoding, sustitutos de emoji, etc.) compartidas por clasificador y LLM.
 */
public final class InboundTextHeuristics {

    private InboundTextHeuristics() {}

    /**
     * Emoji u otro contenido que llega como {@code ???}, U+FFFD o solo signos de interrogación (transporte/encoding).
     */
    public static boolean looksLikeNoiseOrCorruptedContent(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String s = text.strip();
        if (s.contains("\uFFFD")) {
            return true;
        }
        if ("???".equals(s)) {
            return true;
        }
        if (s.length() >= 3 && s.length() <= 24 && s.chars().allMatch(ch -> ch == '?' || Character.isWhitespace(ch))) {
            return true;
        }
        return false;
    }
}

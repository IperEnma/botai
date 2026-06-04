package com.botai.application.chatbot.service.knowledge;

import java.util.ArrayList;
import java.util.List;

/**
 * Expande la consulta de embedding con turnos recientes de la sesión.
 */
public final class RagQueryExpander {

    private static final int MAX_CHARS_PER_HISTORY_LINE = 200;
    private static final int MAX_TOTAL_QUERY_CHARS = 1200;

    private RagQueryExpander() {}

    /**
     * @param historyLines formato {@code "role: content"} (más antiguo primero).
     */
    public static String buildRetrievalQuery(String userMessage, List<String> historyLines, int historyTurns) {
        String current = userMessage != null ? userMessage.strip() : "";
        if (historyTurns <= 0 || historyLines == null || historyLines.isEmpty()) {
            return trimToMax(current);
        }
        int maxMessages = Math.max(1, historyTurns * 2);
        List<String> recent = historyLines.size() <= maxMessages
                ? historyLines
                : historyLines.subList(historyLines.size() - maxMessages, historyLines.size());

        List<String> parts = new ArrayList<>();
        for (String line : recent) {
            if (line == null || line.isBlank()) {
                continue;
            }
            String trimmed = line.strip();
            if (trimmed.length() > MAX_CHARS_PER_HISTORY_LINE) {
                trimmed = trimmed.substring(0, MAX_CHARS_PER_HISTORY_LINE);
            }
            parts.add(trimmed);
        }
        if (!current.isBlank()) {
            parts.add(current);
        }
        if (parts.isEmpty()) {
            return "";
        }
        return trimToMax(String.join("\n", parts));
    }

    private static String trimToMax(String text) {
        if (text == null) {
            return "";
        }
        if (text.length() <= MAX_TOTAL_QUERY_CHARS) {
            return text;
        }
        return text.substring(0, MAX_TOTAL_QUERY_CHARS);
    }
}

package com.botai.application.chatbot.support;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Heurísticas sobre texto entrante (encoding, sustitutos de emoji, etc.) compartidas por clasificador y LLM.
 */
public final class InboundTextHeuristics {

    private static final List<Pattern> NEW_BOOKING_PATTERNS = List.of(
        Pattern.compile("(?i)\\b(quiero|necesito|me gustar[ií]a|podr[ií]a|puedo)\\b[^.]{0,80}\\b(agendar|reservar|sacar\\s+turno|pedir\\s+hora|hacer\\s+una\\s+cita)\\b"),
        Pattern.compile("(?i)\\b(agendar|reservar|sacar\\s+turno|pedir\\s+hora)\\b"),
        Pattern.compile("(?i)\\b(link|enlace|url)\\b[^.]{0,40}\\b(agenda|reservar|turno|cita)\\b"),
        Pattern.compile("(?i)\\bmand(a|ame|en)\\b[^.]{0,30}\\b(la\\s+)?agenda\\b")
    );

    private static final List<Pattern> VIEW_BOOKINGS_PATTERNS = List.of(
        Pattern.compile("(?i)\\b(mis|mis\\s+propias)\\s+(citas|turnos|reservas)\\b"),
        Pattern.compile("(?i)\\b(ver|consultar|mostrar)\\b[^.]{0,40}\\b(mis\\s+)?(citas|turnos|reservas)\\b"),
        Pattern.compile("(?i)\\bqu[eé]\\s+turnos?\\s+tengo\\b"),
        Pattern.compile("(?i)\\ba\\s+qu[eé]\\s+hora\\s+es\\s+mi\\s+(cita|turno)\\b")
    );

    private static final Pattern HTTP_URL = Pattern.compile("(?i)https?://[^\\s)>\\]]+");

    private InboundTextHeuristics() {}

    /** Usuario pide reservar/agendar una cita nueva (no solo info de horarios). */
    public static boolean looksLikeNewBookingRequest(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String n = text.strip();
        for (Pattern p : NEW_BOOKING_PATTERNS) {
            if (p.matcher(n).find()) {
                return true;
            }
        }
        return false;
    }

    /** Usuario quiere ver o consultar citas ya existentes. */
    public static boolean looksLikeViewAgendaBookings(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String n = text.strip();
        for (Pattern p : VIEW_BOOKINGS_PATTERNS) {
            if (p.matcher(n).find()) {
                return true;
            }
        }
        return false;
    }

    public static boolean containsHttpUrl(String text) {
        return text != null && HTTP_URL.matcher(text).find();
    }

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

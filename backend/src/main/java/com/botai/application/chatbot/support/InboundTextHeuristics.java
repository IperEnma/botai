package com.botai.application.chatbot.support;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Set;
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
        Pattern.compile("(?i)\\b(mis|mis\\s+propias)\\s+(citas|turnos|reservas|agendas)\\b"),
        Pattern.compile("(?i)\\b(ver|consultar|mostrar|saber)\\b[^.]{0,50}\\b(tengo|hay|tienen)\\b[^.]{0,40}\\b(agendas?|citas?|turnos?|reservas?)\\b"),
        Pattern.compile("(?i)\\b(ver|consultar|mostrar)\\b[^.]{0,40}\\b(mis\\s+)?(citas|turnos|reservas|agendas)\\b"),
        Pattern.compile("(?i)\\b(agendas?|citas?|turnos?|reservas?)\\s+pendientes?\\b"),
        Pattern.compile("(?i)\\btengo\\s+(agendas?|citas?|turnos?|reservas?)\\s*(pendientes?|programadas?|reservadas?)?\\b"),
        Pattern.compile("(?i)\\bqu[eé]\\s+(turnos?|citas?|agendas?)\\s+tengo\\b"),
        Pattern.compile("(?i)\\ba\\s+qu[eé]\\s+hora\\s+es\\s+mi\\s+(cita|turno|agenda)\\b")
    );

    private static final Set<String> GREETING_ONLY_TOKENS = Set.of(
        "hola", "holaa", "holaaa", "hey", "hi", "hello", "buenas", "saludos", "saludo",
        "tal", "que", "buen", "buenos", "dia", "dias", "tardes", "noches");

    private static final Pattern GREETING_ONLY_PHRASE = Pattern.compile(
        "^(hola|hey|hi|buenas|saludos|que\\s+tal|buen\\s+dia|buenos\\s+dias|buenas\\s+tardes|buenas\\s+noches)[\\s!?.¡¿]*$",
        Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    private InboundTextHeuristics() {}

    /**
     * Saludo sin pregunta adjunta (p. ej. «Hola», «Buenos días»). No aplica a «Hola, ¿quiénes son?».
     */
    public static boolean looksLikeGreetingOnly(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String n = normalizeForMatch(text.strip());
        if (n.isEmpty()) {
            return false;
        }
        if (containsSubstantiveIntent(n)) {
            return false;
        }
        if (GREETING_ONLY_PHRASE.matcher(n).matches()) {
            return true;
        }
        String[] tokens = n.split("\\s+");
        if (tokens.length == 0 || tokens.length > 5) {
            return false;
        }
        for (String token : tokens) {
            String bare = token.replaceAll("[^a-z0-9]", "");
            if (bare.isEmpty() || !GREETING_ONLY_TOKENS.contains(bare)) {
                return false;
            }
        }
        return true;
    }

    private static boolean containsSubstantiveIntent(String normalized) {
        return normalized.contains("horario")
            || normalized.contains("reserv")
            || normalized.contains("agend")
            || normalized.contains("cita")
            || normalized.contains("turno")
            || normalized.contains("servicio")
            || normalized.contains("precio")
            || normalized.contains("ofrec")
            || normalized.contains("quien")
            || normalized.contains("como")
            || normalized.contains("donde")
            || normalized.contains("cuando")
            || normalized.contains("cancel")
            || normalized.contains("http")
            || normalized.contains("?");
    }

    private static String normalizeForMatch(String text) {
        return Normalizer.normalize(text, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .toLowerCase(Locale.ROOT)
            .trim();
    }

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

    private static final List<Pattern> CONVERSATION_CLOSING_PATTERNS = List.of(
        Pattern.compile("(?i)^(muchas\\s+)?gracias[\\s!?.¡¿]*$"),
        Pattern.compile("(?i)^(ok|okay|dale|listo|perfecto|genial|excelente)[\\s!?.¡¿]*$"),
        Pattern.compile("(?i).*(chau|chao|adi[oó]s|hasta\\s+luego|nos\\s+vemos|bye)\\s*[.!]?$"),
        Pattern.compile("(?i)^(nada\\s+m[aá]s|eso\\s+es\\s+todo|eso\\s+ser[ií]a\\s+todo|ya\\s+est[aá]|no\\s+necesito\\s+m[aá]s)[\\s!?.¡¿]*$"),
        Pattern.compile("(?i)^gracias[,\\s]+(eso\\s+es\\s+todo|nada\\s+m[aá]s|chau|chao|adi[oó]s)[\\s!?.¡¿]*$")
    );

    /**
     * Despedida o cierre sin pregunta nueva (p. ej. «Gracias», «Listo, chau»).
     */
    public static boolean looksLikeConversationClosing(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String n = normalizeForMatch(text.strip());
        if (n.isEmpty() || containsSubstantiveIntent(n)) {
            return false;
        }
        for (Pattern p : CONVERSATION_CLOSING_PATTERNS) {
            if (p.matcher(n).matches()) {
                return true;
            }
        }
        return false;
    }

    /**
     * Respuesta a «¿Te resultó útil?» — {@code true}=útil, {@code false}=no útil, vacío=no reconocido.
     */
    public static java.util.Optional<Boolean> parseFeedbackYesNo(String text) {
        if (text == null || text.isBlank()) {
            return java.util.Optional.empty();
        }
        String n = normalizeForMatch(text.strip()).replaceAll("[^a-z0-9\\s]", "").strip();
        if (n.isEmpty()) {
            return java.util.Optional.empty();
        }
        if (Set.of("si", "sip", "see", "yes", "y", "1", "util", "bueno", "bien", "ok", "dale").contains(n)
            || n.startsWith("si ") || n.startsWith("muy util")) {
            return java.util.Optional.of(true);
        }
        if (Set.of("no", "nop", "nope", "mal", "0", "n").contains(n)
            || n.startsWith("no ") || n.contains("no util") || n.contains("no fue util")) {
            return java.util.Optional.of(false);
        }
        return java.util.Optional.empty();
    }

    public static boolean containsHttpUrl(String text) {
        return BookingUrlSanitizer.containsHttpUrl(text);
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

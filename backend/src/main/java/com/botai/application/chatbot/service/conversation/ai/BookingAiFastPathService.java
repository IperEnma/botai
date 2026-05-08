package com.botai.application.chatbot.service.conversation.ai;

import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.infrastructure.chatbot.ai.AgendarTools;
import com.botai.infrastructure.chatbot.booking.BookingContextSanitizer;
import com.botai.infrastructure.chatbot.booking.CustomerDocumentNormalizer;
import com.botai.infrastructure.chatbot.booking.ServiceNameMatcher;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import com.botai.infrastructure.agenda.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.agenda.support.AgendaPrimaryBusinessResolver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Intento determinístico de {@link AgendarTools#agendarCita} cuando el flujo es de agendamiento por IA:
 * si del historial reciente + mensaje actual se deducen servicio, fecha, hora, nombre y documento, se llama la misma
 * lógica que la tool (horario + cupos) sin depender de que el modelo invoque herramientas.
 */
@Service
public class BookingAiFastPathService {

    private static final Logger log = LoggerFactory.getLogger(BookingAiFastPathService.class);

    private static final Pattern ISO_DATE = Pattern.compile("\\b(20\\d{2}-[01]\\d-[0-3]\\d)\\b");
    private static final Pattern TIME_IN_MESSAGE = Pattern.compile("\\b([01]?[0-9]|2[0-3])[:\\.]([0-5][0-9])\\b");
    /** "a las 9", "las 14" (en punto). */
    private static final Pattern HOUR_ONLY = Pattern.compile("(?i)\\b(?:a\\s+las?|las?)\\s+([01]?[0-9]|2[0-3])\\b");
    private static final Pattern NAME_INTRO = Pattern.compile(
        "(?i)(me\\s+llamo|mi\\s+nombre\\s+es|soy)\\s+([^.\n!?]{3,120})");
    private static final Pattern DOC_IN_TEXT = Pattern.compile("\\b(\\d[\\d.\\-\\s]{4,20}\\d|\\d{5,})\\b");
    private static final Pattern MORNING_TIME_PHRASE = Pattern.compile(
        "(?i)(\\bpor\\s+la\\s+mañana\\b|\\bpor\\s+la\\s+manana\\b|\\ben\\s+la\\s+mañana\\b|\\ben\\s+la\\s+manana\\b|\\bde\\s+la\\s+mañana\\b|\\bde\\s+la\\s+manana\\b)");
    /** Confirmación tras acordar fecha/hora/servicio en el hilo. */
    private static final Pattern AFFIRM_ONLY = Pattern.compile(
        "(?i)^(sí|si|ok|okay|dale|confirmo|confirmar|va|listo|correcto|perfecto|adelante)\\s*\\.?!?$");

    private final AgendarTools agendarTools;
    private final MessageHistoryService messageHistoryService;
    private final ServiceJpaRepository agendaServiceRepository;
    private final AgendaPrimaryBusinessResolver primaryBusinessResolver;

    public BookingAiFastPathService(AgendarTools agendarTools,
                                    MessageHistoryService messageHistoryService,
                                    ServiceJpaRepository agendaServiceRepository,
                                    AgendaPrimaryBusinessResolver primaryBusinessResolver) {
        this.agendarTools = agendarTools;
        this.messageHistoryService = messageHistoryService;
        this.agendaServiceRepository = agendaServiceRepository;
        this.primaryBusinessResolver = primaryBusinessResolver;
    }

    /**
     * @return texto de asistente listo para el usuario (éxito o mensaje de error de la tool), o vacío si no aplica fast path.
     *         Exige nombre completo escrito en el hilo (no basta el perfil de WhatsApp).
     */
    public Optional<String> tryExecute(String tenantId,
                                       String conversationId,
                                       String sessionId,
                                       String userText) {
        if (tenantId == null || tenantId.isBlank() || conversationId == null || conversationId.isBlank()) {
            return Optional.empty();
        }
        List<String> userLines = collectUserLines(conversationId, sessionId, userText);
        if (userLines.isEmpty()) {
            return Optional.empty();
        }
        String blob = String.join("\n", userLines);
        List<ServiceEntity> services = primaryBusinessResolver.findPrimaryBusinessId(tenantId)
            .map(bid -> agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(bid))
            .orElse(List.of());
        if (services.isEmpty()) {
            return Optional.empty();
        }
        Optional<String> serviceGuess = ServiceNameMatcher.bestMatch(blob, services, ServiceEntity::getNombre)
            .map(ServiceEntity::getNombre);
        if (serviceGuess.isEmpty()) {
            return Optional.empty();
        }
        LocalDate today = LocalDate.now();
        LocalDate date = extractDate(blob, today).orElse(null);
        if (date == null) {
            return Optional.empty();
        }
        String lastUserLine = userLines.get(userLines.size() - 1);
        String horaNorm = extractTime(blob, lastUserLine);
        if (horaNorm == null) {
            return Optional.empty();
        }
        String nombre = extractName(userLines, blob).orElse(null);
        if (nombre == null || BookingContextSanitizer.isPlaceholderName(nombre)) {
            return Optional.empty();
        }
        String documento = extractDocument(userLines, blob).orElse(null);
        if (documento == null || BookingContextSanitizer.isPlaceholderDocument(documento)) {
            return Optional.empty();
        }
        String fechaIso = date.format(DateTimeFormatter.ISO_LOCAL_DATE);
        log.info("[BOOK-FAST] Invocando agendarCita determinístico tenant={} servicio={} fecha={} hora={}",
            tenantId, serviceGuess.get(), fechaIso, horaNorm);
        if (userText != null && AFFIRM_ONLY.matcher(userText.strip()).matches()) {
            log.info("[BOOK-FAST] Mensaje de confirmación corta; datos de reserva tomados del historial");
        }
        String verify = agendarTools.verificarCitaExistentePorDocumento(nombre.strip(), documento);
        String book = agendarTools.agendarCita(serviceGuess.get(), fechaIso, horaNorm, nombre, documento);
        return Optional.of(mergeVerifyAndBook(verify, book));
    }

    /**
     * Antes de agendar, {@link AgendarTools#verificarCitaExistentePorDocumento} informa citas vigentes con esa cédula.
     * Si no hay ninguna, no duplicamos texto; si hay, el usuario ve el contexto y el resultado del agendamiento.
     */
    static String mergeVerifyAndBook(String verifyToolOutput, String bookToolOutput) {
        if (verifyToolOutput == null) {
            return bookToolOutput != null ? bookToolOutput : "";
        }
        if (bookToolOutput == null) {
            return verifyToolOutput;
        }
        String v = verifyToolOutput.strip();
        String b = bookToolOutput.strip();
        if (v.startsWith("No hay cita registrada")) {
            return b;
        }
        if (v.contains("Falta el nombre") || v.contains("Falta el documento")
            || v.contains("No se pudo identificar")) {
            return b;
        }
        return v + "\n\n" + b;
    }

    private List<String> collectUserLines(String conversationId, String sessionId, String userText) {
        List<String> lines = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();
        for (String row : messageHistoryService.getHistory(conversationId, sessionId)) {
            if (row != null && row.startsWith("user: ")) {
                String c = row.substring(6).strip();
                if (!c.isEmpty()) {
                    lines.add(c);
                    seen.add(c);
                }
            }
        }
        if (userText != null) {
            String u = userText.strip();
            if (!u.isEmpty() && seen.add(u)) {
                lines.add(u);
            }
        }
        return lines;
    }

    private static Optional<LocalDate> extractDate(String blob, LocalDate today) {
        LocalDate lastIso = null;
        Matcher iso = ISO_DATE.matcher(blob);
        while (iso.find()) {
            try {
                LocalDate d = LocalDate.parse(iso.group(1), DateTimeFormatter.ISO_LOCAL_DATE);
                if (!d.isBefore(today)) {
                    lastIso = d;
                }
            } catch (DateTimeParseException ignored) {
            }
        }
        if (lastIso != null) {
            return Optional.of(lastIso);
        }
        if (MORNING_TIME_PHRASE.matcher(blob).find()) {
            return Optional.empty();
        }
        String key = ServiceNameMatcher.normalizeKey(blob);
        if (key.contains("pasado manana")) {
            return Optional.of(today.plusDays(2));
        }
        if (key.contains("manana")) {
            return Optional.of(today.plusDays(1));
        }
        if (key.contains("hoy")) {
            return Optional.of(today);
        }
        return Optional.empty();
    }

    private static String extractTime(String blob, String lastUserLine) {
        String fromLast = parseTimeFromText(lastUserLine);
        if (fromLast != null) {
            return fromLast;
        }
        return parseTimeFromText(blob);
    }

    private static String parseTimeFromText(String message) {
        if (message == null || message.isBlank()) {
            return null;
        }
        Matcher m = TIME_IN_MESSAGE.matcher(message);
        String last = null;
        while (m.find()) {
            last = normalizeTime(m.group(1) + ":" + m.group(2));
        }
        if (last != null) {
            return last;
        }
        Matcher h = HOUR_ONLY.matcher(message);
        while (h.find()) {
            last = normalizeTime(h.group(1));
        }
        return last;
    }

    private static int parseTimeToMinutes(String time) {
        if (time == null || time.isBlank()) {
            return -1;
        }
        String t = time.trim().replace(".", ":");
        String[] parts = t.split(":");
        if (parts.length < 2) {
            try {
                int hour = Integer.parseInt(t.trim());
                if (hour >= 0 && hour <= 23) {
                    return hour * 60;
                }
            } catch (NumberFormatException ignored) {
            }
            return -1;
        }
        try {
            int h = Integer.parseInt(parts[0].trim());
            int min = Integer.parseInt(parts[1].trim());
            if (h < 0 || h > 23 || min < 0 || min > 59) {
                return -1;
            }
            return h * 60 + min;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private static String normalizeTime(String time) {
        if (time == null || time.isBlank()) {
            return time;
        }
        String t = time.trim().replace(".", ":");
        if (!t.contains(":")) {
            try {
                int h = Integer.parseInt(t.trim());
                if (h >= 0 && h <= 23) {
                    return String.format("%02d:00", h);
                }
            } catch (NumberFormatException ignored) {
            }
        }
        int m = parseTimeToMinutes(t);
        return m >= 0 ? String.format("%02d:%02d", m / 60, m % 60) : time;
    }

    private static Optional<String> extractName(List<String> userLines, String blob) {
        Matcher intro = NAME_INTRO.matcher(blob);
        if (intro.find()) {
            String n = intro.group(2).strip();
            if (n.length() >= 3 && !BookingContextSanitizer.isPlaceholderName(n)) {
                return Optional.of(n);
            }
        }
        for (int i = userLines.size() - 1; i >= 0; i--) {
            String line = userLines.get(i);
            if (looksLikePersonNameLine(line)) {
                return Optional.of(line.strip());
            }
        }
        return Optional.empty();
    }

    /**
     * Línea suelta que parece nombre: ≥3 palabras (p. ej. "Ana María López") y sin señales de pedido de cita.
     * Nombres de dos palabras solo vía patrón "me llamo / soy" arriba.
     */
    private static boolean looksLikePersonNameLine(String s) {
        if (s == null) {
            return false;
        }
        String t = s.strip();
        if (t.length() < 5) {
            return false;
        }
        if (BookingContextSanitizer.isPlaceholderName(t)) {
            return false;
        }
        boolean hasLetter = t.chars().anyMatch(Character::isLetter);
        int digitCount = (int) t.chars().filter(Character::isDigit).count();
        if (!hasLetter || digitCount > 0) {
            return false;
        }
        String key = ServiceNameMatcher.normalizeKey(t);
        if (key.contains("cita") || key.contains("agendar") || key.contains("reserva") || key.contains("turno")
            || key.contains("quiero") || key.contains("necesito") || key.contains("disponib")
            || key.contains("manana") || key.contains("hoy") || key.contains("hora") || key.contains("fecha")) {
            return false;
        }
        String normalized = t.replaceAll("[^\\p{L}\\s'-]", " ")
            .replaceAll("\\s{2,}", " ")
            .strip();
        int words = normalized.isEmpty() ? 0 : normalized.split("\\s+").length;
        return words >= 3;
    }

    private static Optional<String> extractDocument(List<String> userLines, String blob) {
        String best = null;
        int bestLen = 0;
        for (String line : userLines) {
            Matcher m = DOC_IN_TEXT.matcher(line);
            while (m.find()) {
                String norm = CustomerDocumentNormalizer.normalize(m.group(1));
                if (norm.length() >= 5 && norm.length() > bestLen) {
                    best = m.group(1);
                    bestLen = norm.length();
                }
            }
        }
        if (best != null && !BookingContextSanitizer.isPlaceholderDocument(best)) {
            return Optional.of(best);
        }
        Matcher m = DOC_IN_TEXT.matcher(blob);
        while (m.find()) {
            String norm = CustomerDocumentNormalizer.normalize(m.group(1));
            if (norm.length() >= 5 && norm.length() > bestLen) {
                best = m.group(1);
                bestLen = norm.length();
            }
        }
        if (best != null && !BookingContextSanitizer.isPlaceholderDocument(best)) {
            return Optional.of(best);
        }
        return Optional.empty();
    }
}

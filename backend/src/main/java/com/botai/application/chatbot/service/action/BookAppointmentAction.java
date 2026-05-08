package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.infrastructure.chatbot.booking.CustomerDocumentNormalizer;
import com.botai.infrastructure.chatbot.booking.ServiceNameMatcher;
import com.botai.infrastructure.chatbot.persistence.entity.AppointmentEntity;
import com.botai.infrastructure.chatbot.persistence.entity.ServiceEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.AppointmentJpaRepository;
import com.botai.infrastructure.chatbot.persistence.jpa.ServiceJpaRepository;
import com.botai.domain.chatbot.service.BotAction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Flujo para agendar cita: nombre -> documento (verificar duplicado por cédula) -> servicio -> fecha -> hora -> confirmar.
 * Con IA activa: el usuario puede escribir en lenguaje natural (ej. "desarrollo de software para mañana") y se parsea servicio y fecha del mensaje, sin exigir número. Solo en modo FAQ se usa selección por número.
 */
@Component
public class BookAppointmentAction implements BotAction {

    private static final Logger log = LoggerFactory.getLogger(BookAppointmentAction.class);
    private static final String ACTION_ID = "book_appointment";
    private static final Pattern TIME_PATTERN = Pattern.compile("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$");
    private static final Pattern ISO_DATE_IN_TEXT = Pattern.compile("\\b(20\\d{2}-[01]\\d-[0-3]\\d)\\b");
    private static final Pattern TIME_IN_MESSAGE = Pattern.compile("\\b([01]?[0-9]|2[0-3])[:\\.]([0-5][0-9])\\b");
    /** "cita" como palabra (cita/reserva), no subcadena de "solicita". */
    private static final Pattern APPOINTMENT_CITA_WORD = Pattern.compile("(^|[^a-z])cita([^a-z]|$)");

    private final ConversationRepository conversationRepository;
    private final AppointmentJpaRepository appointmentRepository;
    private final ServiceJpaRepository serviceRepository;
    private final FeatureFlagService featureFlagService;

    public BookAppointmentAction(ConversationRepository conversationRepository,
                                 AppointmentJpaRepository appointmentRepository,
                                 ServiceJpaRepository serviceRepository,
                                 FeatureFlagService featureFlagService) {
        this.conversationRepository = conversationRepository;
        this.appointmentRepository = appointmentRepository;
        this.serviceRepository = serviceRepository;
        this.featureFlagService = featureFlagService;
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public String getTriggerIntent() {
        return "agendar";
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio. Intenta de nuevo.")
                .conversationId(state.getConversationId())
                .tenantId(tenantId != null ? tenantId : "")
                .build();
        }
        Map<String, Object> ctx = new HashMap<>(state.getContext());
        String step = (String) ctx.get("step");

        // step=service/date/time/confirm sin nombre+cédula (p. ej. contexto viejo de la IA) → reiniciar identificación
        if (step != null && needsCustomerIdentityForStep(step) && missingCustomerIdentity(ctx)) {
            log.info("[BOOK] Contexto inconsistente (step={} sin identidad cliente) -> name_early", step);
            ctx.put("step", "name_early");
            saveState(state, ctx);
            return OutboundMessage.builder()
                .text("Para agendar necesitamos tus datos. ¿Cuál es tu nombre completo?")
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }

        if (step == null || step.isBlank()) {
            List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
            if (services.isEmpty()) {
                conversationRepository.clearIntent(state.getConversationId());
                return OutboundMessage.builder()
                    .text("No hay servicios configurados para agendar. Contacta al negocio.")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            ctx.put("step", "name_early");
            saveState(state, ctx);
            return OutboundMessage.builder()
                .text("Para agendar necesitamos tus datos. ¿Cuál es tu nombre completo?")
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }

        switch (step) {
            case "name_early" -> {
                String name = userInput != null ? userInput.strip() : "";
                if (name.isEmpty() || isWeakCustomerName(name)) {
                    return OutboundMessage.builder()
                        .text("Indica tu nombre completo (no uses abreviaturas genéricas como \"cliente\") para continuar.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeBookingIntentPhrase(name)) {
                    return OutboundMessage.builder()
                        .text("Ya estamos agendando. Escribe tu nombre completo (persona), no una frase para pedir cita.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeDocumentNumberOnly(name)) {
                    return OutboundMessage.builder()
                        .text("Ese dato parece un número de documento. Primero escribe tu nombre completo; en el siguiente paso te pediré la cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeDocumentOrComplaintPhrase(name)) {
                    return OutboundMessage.builder()
                        .text("Eso no parece un nombre. Escribe tu nombre y apellido (persona). La cédula la pedimos en el mensaje siguiente.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("customerName", name);
                ctx.put("step", "document_early");
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("Gracias. ¿Cuál es tu número de cédula o documento?")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "document_early" -> {
                List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
                if (services.isEmpty()) {
                    conversationRepository.clearIntent(state.getConversationId());
                    return OutboundMessage.builder()
                        .text("No hay servicios configurados para agendar. Contacta al negocio.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                String doc = userInput != null ? userInput.strip() : "";
                if (doc.isEmpty()) {
                    return OutboundMessage.builder()
                        .text("El documento es obligatorio. Escribe tu número de cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                String normalizedDoc = CustomerDocumentNormalizer.normalize(doc);
                if (normalizedDoc.isEmpty()) {
                    return OutboundMessage.builder()
                        .text("El documento no es válido. Indica tu número de cédula o documento (solo letras y números).")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (!containsDigit(normalizedDoc) && normalizedDoc.length() > 4) {
                    return OutboundMessage.builder()
                        .text("Necesito el número de tu cédula o documento (con dígitos), no un mensaje de texto. Escríbelo tal como figura en el documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                Optional<AppointmentEntity> existing = findScheduledAppointmentForDocument(tenantId, normalizedDoc);
                if (existing.isPresent()) {
                    AppointmentEntity e = existing.get();
                    conversationRepository.clearIntent(state.getConversationId());
                    return OutboundMessage.builder()
                        .text("Ya tienes una cita agendada el " + e.getAppointmentDate() + " a las " + e.getAppointmentTime()
                            + " (" + e.getServiceName() + "). No podemos agendar otra con el mismo documento mientras esa cita siga vigente.\n\nSi necesitas modificarla, contacta al negocio.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("customerDocument", normalizedDoc);
                ctx.put("step", "service");
                saveState(state, ctx);
                boolean aiOn = featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
                return OutboundMessage.builder()
                    .text(buildServiceSelectionPrompt(services, aiOn))
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            /** Legado: flujo antiguo (servicio → … → hora → nombre → documento). */
            case "name" -> {
                String name = userInput != null ? userInput.strip() : "";
                if (name.isEmpty() || isWeakCustomerName(name)) {
                    return OutboundMessage.builder()
                        .text("Indica tu nombre completo para continuar.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeBookingIntentPhrase(name)) {
                    return OutboundMessage.builder()
                        .text("Ya estamos agendando. Escribe tu nombre completo (persona), no una frase para pedir cita.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeDocumentNumberOnly(name)) {
                    return OutboundMessage.builder()
                        .text("Ese dato parece un número de documento. Primero escribe tu nombre completo; luego te pediré la cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (looksLikeDocumentOrComplaintPhrase(name)) {
                    return OutboundMessage.builder()
                        .text("Eso no parece un nombre. Escribe tu nombre y apellido. La cédula la pedimos después.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("customerName", name);
                ctx.put("step", "document");
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("¿Número de cédula o documento?")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            /** Legado: tras nombre en flujo antiguo; pasa a confirmación si no hay duplicado. */
            case "document" -> {
                String doc = userInput != null ? userInput.strip() : "";
                if (doc.isEmpty()) {
                    return OutboundMessage.builder()
                        .text("El documento es obligatorio. Escribe tu número de cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                String normalizedDoc = CustomerDocumentNormalizer.normalize(doc);
                if (normalizedDoc.isEmpty()) {
                    return OutboundMessage.builder()
                        .text("El documento no es válido. Indica tu cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                if (!containsDigit(normalizedDoc) && normalizedDoc.length() > 4) {
                    return OutboundMessage.builder()
                        .text("Necesito el número de tu cédula o documento (con dígitos), no un mensaje de texto.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                Optional<AppointmentEntity> existing = findScheduledAppointmentForDocument(tenantId, normalizedDoc);
                if (existing.isPresent()) {
                    AppointmentEntity e = existing.get();
                    conversationRepository.clearIntent(state.getConversationId());
                    return OutboundMessage.builder()
                        .text("Ya tienes una cita agendada el " + e.getAppointmentDate() + " a las " + e.getAppointmentTime()
                            + " (" + e.getServiceName() + "). No podemos agendar otra con el mismo documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("customerDocument", normalizedDoc);
                ctx.put("step", "confirm");
                saveState(state, ctx);
                String serviceName = (String) ctx.get("serviceName");
                String date = (String) ctx.get("appointmentDate");
                String time = (String) ctx.get("appointmentTime");
                String customerName = (String) ctx.get("customerName");
                return OutboundMessage.builder()
                    .text("Confirma tu cita:\n• Servicio: " + serviceName + "\n• Fecha: " + date + "\n• Hora: " + time + "\n• Nombre: " + customerName + "\n• Documento: " + normalizedDoc + "\n\nResponde SÍ para confirmar o NO para cancelar.")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "service" -> {
                List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
                if (services.isEmpty()) {
                    conversationRepository.clearIntent(state.getConversationId());
                    return OutboundMessage.builder()
                        .text("No hay servicios configurados para agendar. Contacta al negocio.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                boolean aiOn = featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
                String rawInput = userInput.strip();
                ServiceEntity chosen = null;
                LocalDate parsedDate = null;
                String parsedTimeFromMsg = null;

                if (rawInput.matches("\\d+")) {
                    int idx = Integer.parseInt(rawInput);
                    if (idx >= 1 && idx <= services.size()) {
                        chosen = services.get(idx - 1);
                    }
                }
                if (chosen == null && aiOn) {
                    chosen = ServiceNameMatcher.bestMatch(rawInput, services).orElse(null);
                    parsedDate = parseDateFromMessage(rawInput);
                    parsedTimeFromMsg = parseTimeFromMessage(rawInput);
                }

                if (!aiOn || chosen == null) {
                    if (!aiOn) {
                        if (chosen == null) {
                            chosen = services.stream()
                                .filter(s -> normalizeForMatch(s.getName()).equals(normalizeForMatch(rawInput)))
                                .findFirst()
                                .orElse(null);
                        }
                        if (chosen == null) {
                            chosen = services.stream()
                                .filter(s -> normalizeForMatch(rawInput).contains(normalizeForMatch(s.getName())))
                                .findFirst()
                                .orElse(null);
                        }
                        if (chosen == null) {
                            chosen = ServiceNameMatcher.bestMatch(rawInput, services).orElse(null);
                        }
                    }
                    if (chosen == null) {
                        String serviceList = aiOn
                            ? "Puedes escribir el nombre del servicio que deseas. Ofrecemos: " + services.stream().map(ServiceEntity::getName).reduce((a, b) -> a + ", " + b).orElse("") + "."
                            : "Nuestros servicios son:\n" + buildNumberedServiceList(services) + "Indica el número o el nombre del servicio que deseas.";
                        return OutboundMessage.builder()
                            .text("No ofrecemos ese servicio. " + serviceList)
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                }

                ctx.put("serviceName", chosen.getName());

                if (aiOn && parsedDate != null && !parsedDate.isBefore(LocalDate.now())) {
                    ctx.put("appointmentDate", parsedDate.toString());
                    if (parsedTimeFromMsg != null && TIME_PATTERN.matcher(parsedTimeFromMsg).matches()) {
                        ctx.put("step", "confirm");
                        ctx.put("appointmentTime", parsedTimeFromMsg);
                        saveState(state, ctx);
                        String customerName = (String) ctx.get("customerName");
                        String customerDocument = (String) ctx.get("customerDocument");
                        return OutboundMessage.builder()
                            .text("Confirma tu cita:\n• Servicio: " + chosen.getName() + "\n• Fecha: " + parsedDate
                                + "\n• Hora: " + parsedTimeFromMsg + "\n• Nombre: " + customerName + "\n• Documento: "
                                + customerDocument + "\n\nResponde SÍ para confirmar o NO para cancelar.")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                    ctx.put("step", "time");
                    saveState(state, ctx);
                    return OutboundMessage.builder()
                        .text("¿A qué hora? (ej: 09:00 o 14:30)")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("step", "date");
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("¿Para qué fecha? (ej: 2025-03-25 o escribe 'mañana')")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "date" -> {
                LocalDate date = parseDate(userInput.strip());
                if (date == null || date.isBefore(LocalDate.now())) {
                    return OutboundMessage.builder()
                        .text("Fecha no válida o ya pasada. Indica una fecha (ej: 2025-03-25) o 'mañana'.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("step", "time");
                ctx.put("appointmentDate", date.toString());
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("¿A qué hora? (ej: 09:00 o 14:30)")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "time" -> {
                String time = userInput.strip().replace(".", ":");
                if (!TIME_PATTERN.matcher(time).matches()) {
                    return OutboundMessage.builder()
                        .text("Hora no válida. Usa formato 09:00 o 14:30.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                time = normalizeTime(time);
                ctx.put("step", "confirm");
                ctx.put("appointmentTime", time);
                saveState(state, ctx);
                String serviceName = (String) ctx.get("serviceName");
                String date = (String) ctx.get("appointmentDate");
                String customerName = (String) ctx.get("customerName");
                String customerDocument = (String) ctx.get("customerDocument");
                return OutboundMessage.builder()
                    .text("Confirma tu cita:\n• Servicio: " + serviceName + "\n• Fecha: " + date + "\n• Hora: " + time + "\n• Nombre: " + customerName + "\n• Documento: " + customerDocument + "\n\nResponde SÍ para confirmar o NO para cancelar.")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "confirm" -> {
                String resp = userInput.strip().toLowerCase();
                if (resp.startsWith("s") || resp.equals("si") || resp.equals("sí")) {
                    String customerName = (String) ctx.get("customerName");
                    if (customerName == null || customerName.isBlank()) {
                        ctx.put("step", "name_early");
                        saveState(state, ctx);
                        return OutboundMessage.builder()
                            .text("Falta tu nombre. ¿Cuál es tu nombre completo?")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                    String docStored = (String) ctx.get("customerDocument");
                    String normalizedDoc = CustomerDocumentNormalizer.normalize(docStored != null ? docStored : "");
                    if (normalizedDoc.isEmpty()) {
                        ctx.put("step", "document_early");
                        saveState(state, ctx);
                        return OutboundMessage.builder()
                            .text("Falta un documento válido. ¿Cuál es tu número de cédula o documento?")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                    Optional<AppointmentEntity> dup = findScheduledAppointmentForDocument(tenantId, normalizedDoc);
                    if (dup.isPresent()) {
                        AppointmentEntity e = dup.get();
                        conversationRepository.clearIntent(state.getConversationId());
                        return OutboundMessage.builder()
                            .text("No se guardó la cita: ya existe una reserva con este documento el " + e.getAppointmentDate()
                                + " a las " + e.getAppointmentTime() + " (" + e.getServiceName() + ").")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                    AppointmentEntity apt = new AppointmentEntity();
                    apt.setTenantId(tenantId);
                    apt.setServiceName((String) ctx.get("serviceName"));
                    apt.setAppointmentDate(LocalDate.parse((String) ctx.get("appointmentDate")));
                    apt.setAppointmentTime((String) ctx.get("appointmentTime"));
                    apt.setCustomerName(customerName.strip());
                    apt.setCustomerDocument(normalizedDoc);
                    apt.setUserId(state.getUserId());
                    apt.setStatus("scheduled");
                    appointmentRepository.save(apt);
                    conversationRepository.clearIntent(state.getConversationId());
                    return OutboundMessage.builder()
                        .text("✅ Cita agendada correctamente. Te esperamos.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                conversationRepository.clearIntent(state.getConversationId());
                return OutboundMessage.builder()
                    .text("Agendado cancelado. Si quieres agendar otra vez, escribe 'agendar' o usa el menú.")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            default -> {
                conversationRepository.clearIntent(state.getConversationId());
                return null;
            }
        }
    }

    private static boolean needsCustomerIdentityForStep(String s) {
        return "service".equals(s) || "date".equals(s) || "time".equals(s) || "confirm".equals(s);
    }

    private static boolean missingCustomerIdentity(Map<String, Object> ctx) {
        Object n = ctx.get("customerName");
        Object d = ctx.get("customerDocument");
        return n == null || n.toString().isBlank() || d == null || d.toString().isBlank();
    }

    private Optional<AppointmentEntity> findScheduledAppointmentForDocument(String tenantId, String normalizedDocument) {
        if (normalizedDocument == null || normalizedDocument.isEmpty()) {
            return Optional.empty();
        }
        List<AppointmentEntity> list = appointmentRepository
            .findByTenantIdAndCustomerDocumentAndStatusAndAppointmentDateGreaterThanEqualOrderByAppointmentDateAscAppointmentTimeAsc(
                tenantId, normalizedDocument, "scheduled", LocalDate.now());
        return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
    }

    private static String buildServiceSelectionPrompt(List<ServiceEntity> services, boolean aiOn) {
        StringBuilder sb = new StringBuilder();
        if (aiOn) {
            sb.append("¿Qué servicio deseas y para qué fecha? Puedes escribirlo en una frase (ej.: \"manicura para mañana\").\nServicios que ofrecemos: ");
            sb.append(services.stream().map(ServiceEntity::getName).reduce((a, b) -> a + ", " + b).orElse(""));
            sb.append(".");
        } else {
            sb.append("¿Qué servicio deseas? Opciones:\n");
            for (int i = 0; i < services.size(); i++) {
                sb.append(i + 1).append(". ").append(services.get(i).getName()).append("\n");
            }
        }
        return sb.toString().trim();
    }

    private static boolean isWeakCustomerName(String name) {
        if (name == null || name.strip().length() < 2) return true;
        String n = normalizeForMatch(name);
        return n.equals("cliente whatsapp") || n.equals("por confirmar") || n.equals("cliente") || n.equals("n/a");
    }

    private static boolean containsDigit(String s) {
        if (s == null || s.isEmpty()) return false;
        return s.chars().anyMatch(Character::isDigit);
    }

    /** Solo dígitos (p. ej. cédula) en el paso de nombre: el usuario se adelantó al documento. */
    private static boolean looksLikeDocumentNumberOnly(String text) {
        if (text == null || text.isBlank()) return false;
        String t = text.strip().replaceAll("\\s+", "");
        if (t.length() < 6) return false;
        return t.chars().allMatch(Character::isDigit);
    }

    /**
     * Frases sobre cédula/documento o quejas ("ya te la di") cuando el paso pide nombre.
     */
    private static boolean looksLikeDocumentOrComplaintPhrase(String text) {
        if (text == null || text.isBlank()) return false;
        String n = normalizeForMatch(text);
        if (n.contains("cedula") || n.contains("documento") || n.contains("dni")) return true;
        if (n.contains("te acabo") || n.contains("acabo de dar") || n.contains("te la di") || n.contains("te lo di")) return true;
        if (n.contains("ya te ") && (n.contains("di") || n.contains("pase") || n.contains("mande"))) return true;
        if (n.startsWith("que te ") || n.contains(" que te ")) return true;
        return false;
    }

    /**
     * Evita guardar como nombre frases tipo "quiero agendar". No usa "cita" suelta (falso positivo en "solicita").
     */
    private static boolean looksLikeBookingIntentPhrase(String text) {
        if (text == null || text.isBlank()) return false;
        String n = normalizeForMatch(text);
        if (n.contains("agendar") || n.contains("reservar") || n.contains("turno")) return true;
        if (n.contains("quiero una cita") || n.contains("pedir cita") || n.contains("sacar cita")
            || n.contains("hacer una cita") || n.contains("para la cita") || n.contains("una cita")) return true;
        return APPOINTMENT_CITA_WORD.matcher(n).find();
    }

    private void saveState(ConversationState state, Map<String, Object> ctx) {
        conversationRepository.save(ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(ACTION_ID)
            .context(ctx)
            .build());
    }

    private static int parseTimeToMinutes(String time) {
        if (time == null || time.isBlank()) return -1;
        String t = time.trim().replace(".", ":");
        String[] parts = t.split(":");
        if (parts.length < 2) return -1;
        try {
            int h = Integer.parseInt(parts[0].trim());
            int min = Integer.parseInt(parts[1].trim());
            if (h < 0 || h > 23 || min < 0 || min > 59) return -1;
            return h * 60 + min;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /** "9:00" -> "09:00". */
    private static String normalizeTime(String time) {
        int m = parseTimeToMinutes(time);
        return m >= 0 ? String.format("%02d:%02d", m / 60, m % 60) : time;
    }

    private static LocalDate parseDate(String input) {
        if (input == null || input.isBlank()) return null;
        String key = ServiceNameMatcher.normalizeKey(input.strip());
        if ("manana".equals(key)) return LocalDate.now().plusDays(1);
        if ("hoy".equals(key)) return LocalDate.now();
        try {
            return LocalDate.parse(input.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** Extrae fecha de un mensaje libre (ej. "para mañana", "mañana", "el 2025-03-25"). Usa clave sin tildes. */
    private static LocalDate parseDateFromMessage(String message) {
        if (message == null || message.isBlank()) return null;
        String key = ServiceNameMatcher.normalizeKey(message);
        if (key.contains("pasado manana")) return LocalDate.now().plusDays(2);
        if (key.contains("manana") && !key.contains("pasado")) return LocalDate.now().plusDays(1);
        if (key.contains("hoy")) return LocalDate.now();
        var matcher = ISO_DATE_IN_TEXT.matcher(message);
        if (matcher.find()) {
            try {
                return LocalDate.parse(matcher.group(1), DateTimeFormatter.ISO_LOCAL_DATE);
            } catch (DateTimeParseException ignored) { }
        }
        return null;
    }

    /** Primera hora tipo 14:30 o 9:00 en el mensaje (IA / lenguaje natural). */
    private static String parseTimeFromMessage(String message) {
        if (message == null || message.isBlank()) return null;
        var m = TIME_IN_MESSAGE.matcher(message);
        if (m.find()) {
            return normalizeTime(m.group(1) + ":" + m.group(2));
        }
        return null;
    }

    /** Sin acentos ni mayúsculas para comparar "Depilación" con "Depilacion". */
    private static String normalizeForMatch(String s) {
        if (s == null) return "";
        String n = Normalizer.normalize(s, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "").strip().toLowerCase();
        return n;
    }

    private static String buildNumberedServiceList(List<ServiceEntity> services) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < services.size(); i++) {
            sb.append(i + 1).append(". ").append(services.get(i).getName()).append("\n");
        }
        return sb.toString();
    }
}

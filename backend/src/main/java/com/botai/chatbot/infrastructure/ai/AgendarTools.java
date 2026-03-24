package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.prompt.BotPrompts;
import com.botai.chatbot.domain.context.TenantContext;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.infrastructure.booking.BookingContextSanitizer;
import com.botai.chatbot.infrastructure.booking.CustomerDocumentNormalizer;
import com.botai.chatbot.infrastructure.booking.ServiceNameMatcher;
import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import com.botai.chatbot.infrastructure.persistence.entity.AppointmentEntity;
import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.AppointmentJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Tools para que la IA pueda consultar disponibilidad y agendar citas.
 * <p><strong>Sin reglas de lenguaje natural aquí:</strong> fechas solo en ISO (YYYY-MM-DD). Interpretar
 * “mañana”, “pasado mañana”, etc. es responsabilidad del modelo usando la fecha actual del contexto del sistema.
 * Así el chat se mantiene natural en el LLM y las tools siguen siendo contratos técnicos estables.
 */
@Component
public class AgendarTools {

    private static final Logger log = LoggerFactory.getLogger(AgendarTools.class);

    private final BusinessHoursJpaRepository businessHoursRepository;
    private final AppointmentJpaRepository appointmentRepository;
    private final ServiceJpaRepository serviceRepository;
    private final ConversationRepository conversationRepository;

    public AgendarTools(BusinessHoursJpaRepository businessHoursRepository,
                       AppointmentJpaRepository appointmentRepository,
                       ServiceJpaRepository serviceRepository,
                       ConversationRepository conversationRepository) {
        this.businessHoursRepository = businessHoursRepository;
        this.appointmentRepository = appointmentRepository;
        this.serviceRepository = serviceRepository;
        this.conversationRepository = conversationRepository;
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_GET_SLOTS)
    public String getSlotsDisponibles(
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_FECHA_SLOTS) String fecha) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        LocalDate date = parseDate(fecha);
        if (date == null || date.isBefore(LocalDate.now())) {
            return BotPrompts.ToolsAgendar.ERR_FECHA_INVALIDA;
        }
        List<String> slots = getAvailableTimeSlots(tenantId, date);
        if (slots.isEmpty()) {
            return BotPrompts.ToolsAgendar.ERR_SIN_SLOTS;
        }
        return BotPrompts.ToolsAgendar.horasDisponibles(fecha, String.join(", ", slots));
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_VERIFICAR_CITA)
    public String verificarCitaExistentePorDocumento(
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_NOMBRE_VERIF) String nombreCliente,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_DOC_VERIF) String documento) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        if (nombreCliente == null || nombreCliente.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_FALTA_NOMBRE_VERIF;
        }
        if (BookingContextSanitizer.isPlaceholderName(nombreCliente)) {
            return BotPrompts.ToolsAgendar.ERR_NOMBRE_PLACEHOLDER_VERIF;
        }
        if (documento == null || documento.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_VERIF;
        }
        if (BookingContextSanitizer.isPlaceholderDocument(documento)) {
            return BotPrompts.ToolsAgendar.ERR_DOC_PLACEHOLDER_VERIF;
        }
        String normalized = CustomerDocumentNormalizer.normalize(documento);
        if (normalized.isEmpty()) {
            return BotPrompts.ToolsAgendar.ERR_DOC_INVALIDO;
        }
        List<AppointmentEntity> existing = appointmentRepository
                .findByTenantIdAndCustomerDocumentAndStatusAndAppointmentDateGreaterThanEqualOrderByAppointmentDateAscAppointmentTimeAsc(
                        tenantId, normalized, "scheduled", LocalDate.now());
        if (existing.isEmpty()) {
            return BotPrompts.ToolsAgendar.MSG_SIN_CITA_PREVIA;
        }
        if (existing.size() == 1) {
            AppointmentEntity a = existing.get(0);
            return BotPrompts.ToolsAgendar.citaDuplicadaVerificacion(
                String.valueOf(a.getAppointmentDate()),
                String.valueOf(a.getAppointmentTime()),
                a.getServiceName());
        }
        return formatCitasMultiplesVerificacion(existing);
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_CANCELAR_CITA)
    public String cancelarCita(
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_DOC_CANCELAR) String documento,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_FECHA_CANCELAR) String fecha,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_HORA_CANCELAR) String hora) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        String docRaw = documento != null ? documento.strip() : "";
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, docRaw);
        if (scheduled.isEmpty()) {
            if (isDocumentReliableForCancel(docRaw)) {
                return BotPrompts.ToolsAgendar.MSG_SIN_CITA_CON_ESE_DOCUMENTO;
            }
            String uid = TenantContext.getUserId();
            if (uid == null || uid.isBlank()) {
                return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_CANCELAR;
            }
            return BotPrompts.ToolsAgendar.MSG_SIN_CITA_PARA_CANCELAR;
        }
        LocalDate fechaFiltro = (fecha != null && !fecha.isBlank()) ? parseDate(fecha.strip()) : null;
        String horaNorm = (hora != null && !hora.isBlank()) ? normalizeTime(hora.strip()) : null;

        List<AppointmentEntity> candidates = new ArrayList<>(scheduled);
        if (fechaFiltro != null) {
            candidates = candidates.stream()
                .filter(a -> fechaFiltro.equals(a.getAppointmentDate()))
                .collect(Collectors.toList());
        }
        if (horaNorm != null && !candidates.isEmpty()) {
            candidates = candidates.stream()
                .filter(a -> horaNorm.equals(normalizeTime(a.getAppointmentTime())))
                .collect(Collectors.toList());
        }
        if (candidates.isEmpty()) {
            List<String> lines = scheduled.stream()
                .map(a -> "• " + a.getAppointmentDate() + " " + normalizeTime(a.getAppointmentTime()) + " — " + a.getServiceName())
                .collect(Collectors.toList());
            return BotPrompts.ToolsAgendar.cancelarSinCoincidencia(lines);
        }
        if (candidates.size() > 1) {
            List<String> lines = candidates.stream()
                .map(a -> "• " + a.getAppointmentDate() + " " + normalizeTime(a.getAppointmentTime()) + " — " + a.getServiceName())
                .collect(Collectors.toList());
            return BotPrompts.ToolsAgendar.cancelarPedirPrecision(lines);
        }
        AppointmentEntity toCancel = candidates.get(0);
        toCancel.setStatus("cancelled");
        appointmentRepository.save(toCancel);
        String logKey = isDocumentReliableForCancel(docRaw)
            ? CustomerDocumentNormalizer.normalize(docRaw)
            : ("whatsappUser:" + Objects.toString(TenantContext.getUserId(), ""));
        log.info("[AGENDAR-TOOL] cancelarCita OK: id={} tenant={} lookup={} fecha={} hora={} -> status=cancelled",
            toCancel.getId(), tenantId, logKey, toCancel.getAppointmentDate(), toCancel.getAppointmentTime());
        return BotPrompts.ToolsAgendar.citaCanceladaOk(
            String.valueOf(toCancel.getAppointmentDate()),
            String.valueOf(toCancel.getAppointmentTime()),
            toCancel.getServiceName());
    }

    /**
     * Cancela todas las citas futuras del mismo criterio que {@link #cancelarCita} sin filtros de fecha/hora
     * (mismo WhatsApp o documento fiable). Invocable por la IA cuando el usuario pide cancelar todas.
     */
    @Tool(description = BotPrompts.ToolsAgendar.TOOL_CANCELAR_TODAS)
    public String cancelarTodasLasCitasDelCanal() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, "");
        if (scheduled.isEmpty()) {
            if (TenantContext.getUserId() == null || TenantContext.getUserId().isBlank()) {
                return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_CANCELAR;
            }
            return BotPrompts.ToolsAgendar.MSG_SIN_CITA_PARA_CANCELAR;
        }
        List<String> detalles = new ArrayList<>();
        for (AppointmentEntity a : scheduled) {
            a.setStatus("cancelled");
            appointmentRepository.save(a);
            detalles.add(String.valueOf(a.getAppointmentDate()) + " "
                + normalizeTime(a.getAppointmentTime()) + " — " + a.getServiceName());
            log.info("[AGENDAR-TOOL] cancelarTodas OK: id={} tenant={} fecha={} hora={} -> status=cancelled",
                a.getId(), tenantId, a.getAppointmentDate(), a.getAppointmentTime());
        }
        return BotPrompts.ToolsAgendar.citasTodasCanceladasOk(scheduled.size(), detalles);
    }

    /**
     * Lista citas futuras activas vinculadas a este WhatsApp (mismo criterio que cancelar con documento vacío).
     * El modelo debe llamarla antes de preguntar «¿cuál cita?» o cuando el usuario pregunte qué citas tiene.
     */
    @Tool(description = BotPrompts.ToolsAgendar.TOOL_LISTAR_CITAS_CANAL)
    public String listarCitasActivasDelCanal() {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, "");
        if (scheduled.isEmpty()) {
            String uid = TenantContext.getUserId();
            if (uid == null || uid.isBlank()) {
                return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_CANCELAR;
            }
            return BotPrompts.ToolsAgendar.MSG_LISTAR_CITAS_CANAL_VACIO;
        }
        List<String> lines = new ArrayList<>();
        for (int i = 0; i < scheduled.size(); i++) {
            AppointmentEntity a = scheduled.get(i);
            lines.add((i + 1) + ") " + a.getAppointmentDate() + " " + normalizeTime(a.getAppointmentTime())
                + " — " + a.getServiceName());
        }
        log.info("[AGENDAR-TOOL] listarCitasActivasDelCanal tenant={} userId={} count={}",
            tenantId, TenantContext.getUserId(), scheduled.size());
        return BotPrompts.ToolsAgendar.citasActivasCanalListado(scheduled.size(), lines);
    }

    /**
     * Cita(s) activas a cancelar: por cédula si es creíble; si no (vacío, placeholder, texto corto tipo "HOLA"),
     * por {@link TenantContext#getUserId()} (WhatsApp) si la cita se guardó con ese usuario al agendar.
     */
    private List<AppointmentEntity> listScheduledForCancel(String tenantId, String docRaw) {
        if (isDocumentReliableForCancel(docRaw)) {
            String nd = CustomerDocumentNormalizer.normalize(docRaw);
            if (nd.isEmpty()) {
                return List.of();
            }
            return appointmentRepository
                .findByTenantIdAndCustomerDocumentAndStatusAndAppointmentDateGreaterThanEqualOrderByAppointmentDateAscAppointmentTimeAsc(
                    tenantId, nd, "scheduled", LocalDate.now());
        }
        String uid = TenantContext.getUserId();
        if (uid == null || uid.isBlank()) {
            return List.of();
        }
        return appointmentRepository.findByTenantIdAndUserIdOrderByAppointmentDateAscAppointmentTimeAsc(tenantId, uid).stream()
            .filter(a -> a.getStatus() != null && "scheduled".equalsIgnoreCase(a.getStatus().strip()))
            .filter(a -> !a.getAppointmentDate().isBefore(LocalDate.now()))
            .collect(Collectors.toList());
    }

    /** Documento con el que tiene sentido buscar en BD (no placeholder, longitud mínima, típico de cédula). */
    private static boolean isDocumentReliableForCancel(String docRaw) {
        if (docRaw == null || docRaw.isBlank()) {
            return false;
        }
        if (BookingContextSanitizer.isPlaceholderDocument(docRaw)) {
            return false;
        }
        String nd = CustomerDocumentNormalizer.normalize(docRaw);
        return nd.length() >= 5;
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_AGENDAR_CITA)
    public String agendarCita(
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_SERVICIO) String servicio,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_FECHA) String fecha,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_HORA) String hora,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_NOMBRE_AGENDAR) String nombreCliente,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_DOC_AGENDAR) String documento) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        if (servicio == null || servicio.isBlank() || fecha == null || fecha.isBlank()
                || hora == null || hora.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_FALTAN_SFH;
        }
        if (nombreCliente == null || nombreCliente.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_FALTA_NOMBRE_AGENDAR;
        }
        if (BookingContextSanitizer.isPlaceholderName(nombreCliente)) {
            return BotPrompts.ToolsAgendar.ERR_NOMBRE_PLACEHOLDER_AGENDAR;
        }
        if (documento == null || documento.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_AGENDAR;
        }
        if (BookingContextSanitizer.isPlaceholderDocument(documento)) {
            return BotPrompts.ToolsAgendar.ERR_DOC_PLACEHOLDER_AGENDAR;
        }
        LocalDate date = parseDate(fecha);
        if (date == null || date.isBefore(LocalDate.now())) {
            return BotPrompts.ToolsAgendar.ERR_FECHA_PASADA;
        }
        List<String> slots = getAvailableTimeSlots(tenantId, date);
        String horaNorm = normalizeTime(hora);
        if (slots.isEmpty()) {
            return BotPrompts.ToolsAgendar.ERR_SIN_HORARIO_VALIDO_PARA_FECHA;
        }
        if (!slots.contains(horaNorm)) {
            return BotPrompts.ToolsAgendar.horaNoDisponible(slots.subList(0, Math.min(10, slots.size())));
        }
        List<ServiceEntity> activeServices = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
        ServiceEntity resolvedService = ServiceNameMatcher.bestMatch(servicio, activeServices).orElse(null);
        if (resolvedService == null) {
            return BotPrompts.ToolsAgendar.ERR_SERVICIO_NO_OFRECIDO;
        }
        String canonicalServiceName = resolvedService.getName();
        String normalizedDoc = CustomerDocumentNormalizer.normalize(documento);
        if (normalizedDoc.isEmpty()) {
            return BotPrompts.ToolsAgendar.ERR_DOC_NORMALIZE_FAIL;
        }
        List<AppointmentEntity> dup = appointmentRepository
                .findByTenantIdAndCustomerDocumentAndStatusAndAppointmentDateGreaterThanEqualOrderByAppointmentDateAscAppointmentTimeAsc(
                        tenantId, normalizedDoc, "scheduled", LocalDate.now());
        // Solo bloquear mismo día + misma hora (misma cédula). Permite otro servicio el mismo día en otro hueco libre.
        for (AppointmentEntity d : dup) {
            if (date.equals(d.getAppointmentDate()) && horaNorm.equals(normalizeTime(d.getAppointmentTime()))) {
                return BotPrompts.ToolsAgendar.citaExistenteMismoDoc(
                    String.valueOf(d.getAppointmentDate()),
                    String.valueOf(d.getAppointmentTime()),
                    d.getServiceName());
            }
        }
        AppointmentEntity apt = new AppointmentEntity();
        apt.setTenantId(tenantId);
        apt.setServiceName(canonicalServiceName);
        apt.setAppointmentDate(date);
        apt.setAppointmentTime(horaNorm);
        apt.setCustomerName(nombreCliente.trim());
        apt.setCustomerDocument(normalizedDoc);
        apt.setUserId(TenantContext.getUserId());
        apt.setStatus("scheduled");
        appointmentRepository.save(apt);
        String convId = TenantContext.getConversationId();
        if (convId != null && !convId.isBlank()) {
            conversationRepository.clearIntent(convId);
        }
        return BotPrompts.ToolsAgendar.citaAgendadaOk(canonicalServiceName, fecha, horaNorm, nombreCliente);
    }

    /** Solo {@code YYYY-MM-DD}. El LLM debe resolver el lenguaje natural del usuario antes de llamar la tool. */
    private static LocalDate parseDate(String input) {
        if (input == null || input.isBlank()) return null;
        try {
            return LocalDate.parse(input.strip(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            return null;
        }
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

    private static String normalizeTime(String time) {
        if (time == null || time.isBlank()) {
            return time;
        }
        String t = time.trim().replace(".", ":");
        // "11", "9" → hora en punto
        if (!t.contains(":")) {
            try {
                int h = Integer.parseInt(t.trim());
                if (h >= 0 && h <= 23) {
                    return String.format("%02d:00", h);
                }
            } catch (NumberFormatException ignored) {
                // sigue con parseo HH:mm
            }
        }
        int m = parseTimeToMinutes(t);
        return m >= 0 ? String.format("%02d:%02d", m / 60, m % 60) : time;
    }

    private BusinessHoursEntity getHoursForDay(String tenantId, LocalDate date) {
        int dayOfWeek = date.getDayOfWeek().getValue();
        return businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId).stream()
                .filter(h -> h.getDayOfWeek() == dayOfWeek)
                .findFirst()
                .orElse(null);
    }

    private List<String> getAvailableTimeSlots(String tenantId, LocalDate date) {
        BusinessHoursEntity h = getHoursForDay(tenantId, date);
        if (h == null || h.getOpenTime() == null || h.getCloseTime() == null) return List.of();
        int openMin = parseTimeToMinutes(h.getOpenTime());
        int closeMin = parseTimeToMinutes(h.getCloseTime());
        if (openMin < 0 || closeMin <= openMin) return List.of();
        // Solo citas activas ocupan hueco; horas normalizadas para coincidir con BD (p. ej. 9:00 vs 09:00).
        List<String> booked = appointmentRepository.findByTenantIdAndAppointmentDateOrderByAppointmentTimeAsc(tenantId, date)
                .stream()
                .filter(a -> a.getStatus() == null || "scheduled".equalsIgnoreCase(a.getStatus().strip()))
                .map(a -> normalizeTime(a.getAppointmentTime()))
                .collect(Collectors.toList());
        List<String> slots = new ArrayList<>();
        for (int m = openMin; m < closeMin; m += 30) {
            String slot = String.format("%02d:%02d", m / 60, m % 60);
            if (!booked.contains(slot)) slots.add(slot);
        }
        return slots;
    }

    private static String formatCitasMultiplesVerificacion(List<AppointmentEntity> list) {
        StringBuilder sb = new StringBuilder(BotPrompts.ToolsAgendar.CITAS_MULT_VERIF_PREFIX);
        for (AppointmentEntity a : list) {
            sb.append("• ").append(a.getAppointmentDate()).append(" ")
                .append(normalizeTime(a.getAppointmentTime())).append(" — ").append(a.getServiceName()).append("\n");
        }
        sb.append(BotPrompts.ToolsAgendar.CITAS_MULT_VERIF_SUFFIX);
        return sb.toString();
    }
}

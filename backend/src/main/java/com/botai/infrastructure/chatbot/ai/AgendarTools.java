package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.infrastructure.security.context.ThreadTenantContext;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.infrastructure.chatbot.booking.BookingContextSanitizer;
import com.botai.infrastructure.chatbot.booking.CustomerDocumentNormalizer;
import com.botai.infrastructure.chatbot.persistence.entity.AppointmentEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.AppointmentJpaRepository;
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
 * Herramientas de IA para citas <strong>ya existentes</strong> en el modelo legacy {@code appointment}
 * (listado y cancelación). Las reservas nuevas y la consulta de turnos Agenda son por enlace público
 * y acción CRM {@code view_agenda_bookings_by_contact} (teléfono del canal), no por cédula en chat.
 */
@Component
public class AgendarTools {

    private static final Logger log = LoggerFactory.getLogger(AgendarTools.class);

    private final AppointmentJpaRepository appointmentRepository;
    private final BotToolCallGuard toolCallGuard;

    public AgendarTools(AppointmentJpaRepository appointmentRepository, BotToolCallGuard toolCallGuard) {
        this.appointmentRepository = appointmentRepository;
        this.toolCallGuard = toolCallGuard;
    }

    private String gated(java.util.function.Supplier<String> action) {
        String blocked = toolCallGuard.gate();
        if (blocked != null) {
            return blocked;
        }
        return action.get();
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_CANCELAR_CITA)
    public String cancelarCita(
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_DOC_CANCELAR) String documento,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_FECHA_CANCELAR) String fecha,
            @ToolParam(description = BotPrompts.ToolsAgendar.PARAM_HORA_CANCELAR) String hora) {
        return gated(() -> cancelarCitaInternal(documento, fecha, hora));
    }

    private String cancelarCitaInternal(String documento, String fecha, String hora) {
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        String docRaw = documento != null ? documento.strip() : "";
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, docRaw);
        if (scheduled.isEmpty()) {
            if (isDocumentReliableForCancel(docRaw)) {
                return BotPrompts.ToolsAgendar.MSG_SIN_CITA_CON_ESE_DOCUMENTO;
            }
            String uid = ThreadTenantContext.getUserId();
            if (uid == null || uid.isBlank()) {
                return BotPrompts.ToolsAgendar.ERR_FALTA_DOC_CANCELAR;
            }
            return BotPrompts.ToolsAgendar.MSG_SIN_CITA_PARA_CANCELAR;
        }
        LocalDate fechaFiltro = (fecha != null && !fecha.isBlank()) ? parseIsoDate(fecha.strip()) : null;
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
            : ("whatsappUser:" + Objects.toString(ThreadTenantContext.getUserId(), ""));
        log.info("[AGENDAR-TOOL] cancelarCita OK: id={} tenant={} lookup={} fecha={} hora={} -> status=cancelled",
            toCancel.getId(), tenantId, logKey, toCancel.getAppointmentDate(), toCancel.getAppointmentTime());
        return BotPrompts.ToolsAgendar.citaCanceladaOk(
            String.valueOf(toCancel.getAppointmentDate()),
            String.valueOf(toCancel.getAppointmentTime()),
            toCancel.getServiceName());
    }

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_CANCELAR_TODAS)
    public String cancelarTodasLasCitasDelCanal() {
        return gated(this::cancelarTodasLasCitasDelCanalInternal);
    }

    private String cancelarTodasLasCitasDelCanalInternal() {
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, "");
        if (scheduled.isEmpty()) {
            if (ThreadTenantContext.getUserId() == null || ThreadTenantContext.getUserId().isBlank()) {
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

    @Tool(description = BotPrompts.ToolsAgendar.TOOL_LISTAR_CITAS_CANAL)
    public String listarCitasActivasDelCanal() {
        return gated(this::listarCitasActivasDelCanalInternal);
    }

    private String listarCitasActivasDelCanalInternal() {
        String tenantId = ThreadTenantContext.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            return BotPrompts.ToolsAgendar.ERR_TENANT_UNKNOWN;
        }
        List<AppointmentEntity> scheduled = listScheduledForCancel(tenantId, "");
        if (scheduled.isEmpty()) {
            String uid = ThreadTenantContext.getUserId();
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
            tenantId, ThreadTenantContext.getUserId(), scheduled.size());
        return BotPrompts.ToolsAgendar.citasActivasCanalListado(scheduled.size(), lines);
    }

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
        String uid = ThreadTenantContext.getUserId();
        if (uid == null || uid.isBlank()) {
            return List.of();
        }
        return appointmentRepository.findByTenantIdAndUserIdOrderByAppointmentDateAscAppointmentTimeAsc(tenantId, uid).stream()
            .filter(a -> a.getStatus() != null && "scheduled".equalsIgnoreCase(a.getStatus().strip()))
            .filter(a -> !a.getAppointmentDate().isBefore(LocalDate.now()))
            .collect(Collectors.toList());
    }

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

    private static LocalDate parseIsoDate(String input) {
        if (input == null || input.isBlank()) return null;
        try {
            return LocalDate.parse(input.strip(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}

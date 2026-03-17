package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.domain.context.TenantContext;
import com.botai.chatbot.infrastructure.persistence.entity.AppointmentEntity;
import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.AppointmentJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tools para que la IA pueda consultar disponibilidad y agendar citas.
 * Usar cuando el usuario quiera agendar, reservar o ver horarios disponibles.
 */
@Component
public class AgendarTools {

    private final BusinessHoursJpaRepository businessHoursRepository;
    private final AppointmentJpaRepository appointmentRepository;
    private final ServiceJpaRepository serviceRepository;

    public AgendarTools(BusinessHoursJpaRepository businessHoursRepository,
                       AppointmentJpaRepository appointmentRepository,
                       ServiceJpaRepository serviceRepository) {
        this.businessHoursRepository = businessHoursRepository;
        this.appointmentRepository = appointmentRepository;
        this.serviceRepository = serviceRepository;
    }

    @Tool(description = "Obtener las horas disponibles para agendar en una fecha. Fecha en formato YYYY-MM-DD (ej: 2025-03-25). Usar cuando el usuario pregunte por horarios disponibles, quiera agendar o elegir hora.")
    public String getSlotsDisponibles(
            @ToolParam(description = "Fecha en formato YYYY-MM-DD, ej: 2025-03-25") String fecha) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return "No se pudo identificar el negocio.";
        }
        LocalDate date = parseDate(fecha);
        if (date == null || date.isBefore(LocalDate.now())) {
            return "Fecha no válida o ya pasada. Usa formato YYYY-MM-DD.";
        }
        List<String> slots = getAvailableTimeSlots(tenantId, date);
        if (slots.isEmpty()) {
            return "No hay horario configurado para ese día o no quedan horas disponibles.";
        }
        return "Horas disponibles el " + fecha + ": " + String.join(", ", slots);
    }

    @Tool(description = "Agendar una cita en el sistema. SOLO llamar cuando tengas TODOS los datos dados por el usuario: servicio, fecha (YYYY-MM-DD), hora (HH:mm), nombre completo del cliente y documento/cédula. Si falta nombre o documento, NO llames esta herramienta: pide al usuario que los indique.")
    public String agendarCita(
            @ToolParam(description = "Nombre del servicio, ej: Depilación") String servicio,
            @ToolParam(description = "Fecha en YYYY-MM-DD") String fecha,
            @ToolParam(description = "Hora en HH:mm, ej: 09:00") String hora,
            @ToolParam(description = "Nombre completo del cliente (debe haberlo dicho el usuario)") String nombreCliente,
            @ToolParam(description = "Documento o cédula del cliente (debe haberlo dicho el usuario)") String documento) {
        String tenantId = TenantContext.get();
        if (tenantId == null || tenantId.isBlank()) {
            return "No se pudo identificar el negocio.";
        }
        if (servicio == null || servicio.isBlank() || fecha == null || fecha.isBlank()
                || hora == null || hora.isBlank()) {
            return "Faltan datos obligatorios: servicio, fecha y hora.";
        }
        if (nombreCliente == null || nombreCliente.isBlank()) {
            return "Falta el nombre del cliente. Pide al usuario que indique su nombre completo antes de agendar.";
        }
        if (isPlaceholderName(nombreCliente)) {
            return "El nombre debe ser el que el usuario indicó, no un valor por defecto. Pregunta: '¿Cuál es tu nombre completo?' y usa la respuesta antes de llamar agendarCita.";
        }
        if (documento == null || documento.isBlank()) {
            return "Falta el documento o cédula del cliente. Pide al usuario que indique su número de documento antes de agendar.";
        }
        if (isPlaceholderDocument(documento)) {
            return "El documento debe ser el que el usuario indicó, no un valor por defecto. Pregunta: '¿Cuál es tu número de cédula o documento?' y usa la respuesta antes de llamar agendarCita.";
        }
        LocalDate date = parseDate(fecha);
        if (date == null || date.isBefore(LocalDate.now())) {
            return "Fecha no válida o ya pasada.";
        }
        List<String> slots = getAvailableTimeSlots(tenantId, date);
        String horaNorm = normalizeTime(hora);
        if (!slots.isEmpty() && !slots.contains(horaNorm)) {
            return "Esa hora no está disponible. Horas disponibles: " + String.join(", ", slots.subList(0, Math.min(10, slots.size())));
        }
        if (serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId).stream()
                .noneMatch(s -> s.getName() != null && normalizeForMatch(s.getName()).contains(normalizeForMatch(servicio)))) {
            return "No ofrecemos ese servicio. Consulta los servicios disponibles con listarServicios.";
        }
        AppointmentEntity apt = new AppointmentEntity();
        apt.setTenantId(tenantId);
        apt.setServiceName(servicio.trim());
        apt.setAppointmentDate(date);
        apt.setAppointmentTime(horaNorm);
        apt.setCustomerName(nombreCliente.trim());
        apt.setCustomerDocument(documento.trim());
        apt.setUserId(TenantContext.getUserId());
        apt.setStatus("scheduled");
        appointmentRepository.save(apt);
        return "Cita agendada correctamente: " + servicio + " el " + fecha + " a las " + horaNorm + " para " + nombreCliente + ".";
    }

    private static String normalizeForMatch(String s) {
        if (s == null) return "";
        return java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").strip().toLowerCase();
    }

    /** Rechaza nombres que son placeholders; el usuario debe dar su nombre real. */
    private static boolean isPlaceholderName(String name) {
        if (name == null || name.isBlank()) return true;
        String n = normalizeForMatch(name);
        return n.equals("cliente whatsapp") || n.equals("por confirmar") || n.equals("cliente")
                || n.equals("n/a");
    }

    /** Rechaza documentos que son placeholders; el usuario debe dar su documento real. */
    private static boolean isPlaceholderDocument(String doc) {
        if (doc == null || doc.isBlank()) return true;
        String d = normalizeForMatch(doc);
        return d.equals("por confirmar") || d.equals("n/a") || d.equals("pendiente");
    }

    private static LocalDate parseDate(String input) {
        if (input == null || input.isBlank()) return null;
        try {
            return LocalDate.parse(input.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
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
        int m = parseTimeToMinutes(time);
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
        List<String> booked = appointmentRepository.findByTenantIdAndAppointmentDateOrderByAppointmentTimeAsc(tenantId, date)
                .stream().map(AppointmentEntity::getAppointmentTime).collect(Collectors.toList());
        List<String> slots = new ArrayList<>();
        for (int m = openMin; m < closeMin; m += 30) {
            String slot = String.format("%02d:%02d", m / 60, m % 60);
            if (!booked.contains(slot)) slots.add(slot);
        }
        return slots;
    }
}

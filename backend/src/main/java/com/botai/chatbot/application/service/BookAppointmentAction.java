package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.infrastructure.persistence.entity.AppointmentEntity;
import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.AppointmentJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
import com.botai.chatbot.domain.service.BotAction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Flujo para agendar cita: servicio -> fecha -> hora -> nombre -> documento -> confirmar.
 */
@Component
public class BookAppointmentAction implements BotAction {

    private static final Logger log = LoggerFactory.getLogger(BookAppointmentAction.class);
    private static final String ACTION_ID = "book_appointment";
    private static final Pattern TIME_PATTERN = Pattern.compile("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$");

    private final ConversationRepository conversationRepository;
    private final AppointmentJpaRepository appointmentRepository;
    private final ServiceJpaRepository serviceRepository;
    private final BusinessHoursJpaRepository businessHoursRepository;

    public BookAppointmentAction(ConversationRepository conversationRepository,
                                 AppointmentJpaRepository appointmentRepository,
                                 ServiceJpaRepository serviceRepository,
                                 BusinessHoursJpaRepository businessHoursRepository) {
        this.conversationRepository = conversationRepository;
        this.appointmentRepository = appointmentRepository;
        this.serviceRepository = serviceRepository;
        this.businessHoursRepository = businessHoursRepository;
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
        String tenantId = state.getContextValue("tenantId", String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio. Intenta de nuevo.")
                .conversationId(state.getConversationId())
                .tenantId(tenantId != null ? tenantId : "")
                .build();
        }
        Map<String, Object> ctx = new HashMap<>(state.getContext());
        String step = (String) ctx.get("step");

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
            StringBuilder sb = new StringBuilder("¿Qué servicio deseas? Opciones:\n");
            for (int i = 0; i < services.size(); i++) {
                sb.append(i + 1).append(". ").append(services.get(i).getName()).append("\n");
            }
            ctx.put("step", "service");
            saveState(state, ctx);
            return OutboundMessage.builder()
                .text(sb.toString().trim())
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }

        switch (step) {
            case "service" -> {
                List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
                String name = userInput.strip();
                ServiceEntity chosen = null;
                if (name.matches("\\d+")) {
                    int idx = Integer.parseInt(name);
                    if (idx >= 1 && idx <= services.size()) chosen = services.get(idx - 1);
                }
                if (chosen == null) {
                    chosen = services.stream()
                        .filter(s -> s.getName().equalsIgnoreCase(name))
                        .findFirst()
                        .orElse(services.isEmpty() ? null : services.get(0));
                }
                if (chosen == null) chosen = services.get(0);
                ctx.put("step", "date");
                ctx.put("serviceName", chosen.getName());
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
                String time = userInput.strip();
                if (!TIME_PATTERN.matcher(time).matches()) {
                    time = time.replace(".", ":");
                    if (!TIME_PATTERN.matcher(time).matches()) {
                        return OutboundMessage.builder()
                            .text("Hora no válida. Usa formato 09:00 o 14:30.")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                }
                ctx.put("step", "name");
                ctx.put("appointmentTime", time);
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("¿Tu nombre completo?")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "name" -> {
                ctx.put("step", "document");
                ctx.put("customerName", userInput.strip());
                saveState(state, ctx);
                return OutboundMessage.builder()
                    .text("¿Número de cédula o documento?")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "document" -> {
                String doc = userInput != null ? userInput.strip() : "";
                if (doc.isEmpty()) {
                    return OutboundMessage.builder()
                        .text("El documento es obligatorio para tu expediente. Por favor escribe tu número de cédula o documento.")
                        .conversationId(state.getConversationId())
                        .tenantId(tenantId)
                        .build();
                }
                ctx.put("step", "confirm");
                ctx.put("customerDocument", doc);
                saveState(state, ctx);
                String serviceName = (String) ctx.get("serviceName");
                String date = (String) ctx.get("appointmentDate");
                String time = (String) ctx.get("appointmentTime");
                String customerName = (String) ctx.get("customerName");
                return OutboundMessage.builder()
                    .text("Confirma tu cita:\n• Servicio: " + serviceName + "\n• Fecha: " + date + "\n• Hora: " + time + "\n• Nombre: " + customerName + "\n• Documento: " + doc + "\n\nResponde SÍ para confirmar o NO para cancelar.")
                    .conversationId(state.getConversationId())
                    .tenantId(tenantId)
                    .build();
            }
            case "confirm" -> {
                String resp = userInput.strip().toLowerCase();
                if (resp.startsWith("s") || resp.equals("si") || resp.equals("sí")) {
                    String doc = (String) ctx.get("customerDocument");
                    if (doc == null || doc.isBlank()) {
                        ctx.put("step", "document");
                        saveState(state, ctx);
                        return OutboundMessage.builder()
                            .text("Falta tu documento para el expediente. ¿Número de cédula o documento?")
                            .conversationId(state.getConversationId())
                            .tenantId(tenantId)
                            .build();
                    }
                    AppointmentEntity apt = new AppointmentEntity();
                    apt.setTenantId(tenantId);
                    apt.setServiceName((String) ctx.get("serviceName"));
                    apt.setAppointmentDate(LocalDate.parse((String) ctx.get("appointmentDate")));
                    apt.setAppointmentTime((String) ctx.get("appointmentTime"));
                    apt.setCustomerName((String) ctx.get("customerName"));
                    apt.setCustomerDocument(doc);
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

    private void saveState(ConversationState state, Map<String, Object> ctx) {
        conversationRepository.save(ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(ACTION_ID)
            .context(ctx)
            .build());
    }

    private static LocalDate parseDate(String input) {
        if (input == null || input.isBlank()) return null;
        String lower = input.toLowerCase().strip();
        if (lower.equals("mañana")) return LocalDate.now().plusDays(1);
        if (lower.equals("hoy")) return LocalDate.now();
        try {
            return LocalDate.parse(input.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}

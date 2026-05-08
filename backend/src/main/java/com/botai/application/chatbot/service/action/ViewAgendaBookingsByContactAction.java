package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Lista citas futuras del módulo Agenda por email o teléfono del cliente (sin OTP).
 */
@Component
public class ViewAgendaBookingsByContactAction implements BotAction {

    public static final String ACTION_ID = "view_agenda_bookings_by_contact";
    private static final String CTX_STEP = "agendaBookingsContactStep";
    private static final String STEP_AWAITING = "awaiting_contact";

    private static final Pattern EMAIL = Pattern.compile(
        "[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}");
    private static final Pattern PHONE_DIGITS = Pattern.compile("(\\+?\\d[\\d\\s.-]{6,}\\d)");

    private static final DateTimeFormatter FMT =
        DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale.forLanguageTag("es-AR"));

    private static final String BASE_SQL = """
        SELECT b.fecha_hora_inicio, b.estado, s.nombre AS svc, bus.nombre AS bname
        FROM agenda_bookings b
        JOIN agenda_services s ON s.id = b.service_id
        JOIN agenda_businesses bus ON bus.id = b.business_id
        JOIN agenda_users u ON u.id = b.user_id
        WHERE bus.tenant_id = ?
          AND b.fecha_hora_inicio >= NOW()
          AND b.estado IN ('PENDING','CONFIRMED')
        """;

    private final ConversationRepository conversationRepository;
    private final JdbcTemplate jdbcTemplate;

    public ViewAgendaBookingsByContactAction(ConversationRepository conversationRepository,
                                            JdbcTemplate jdbcTemplate) {
        this.conversationRepository = conversationRepository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public String getTriggerIntent() {
        return "ver citas";
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String convId = state.getConversationId();
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio.")
                .conversationId(convId)
                .tenantId("")
                .build();
        }

        Map<String, Object> ctx = new HashMap<>(state.getContext());
        String step = (String) ctx.get(CTX_STEP);

        if (step == null && userInput != null) {
            Contact c = tryParseContact(userInput);
            if (c != null) {
                return finishWithQuery(convId, tenantId, c);
            }
            ctx.put(CTX_STEP, STEP_AWAITING);
            conversationRepository.save(ConversationState.builder()
                .conversationId(convId)
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(ACTION_ID)
                .context(ctx)
                .build());
            return OutboundMessage.builder()
                .text("Para buscar tus reservas, indicame el correo o el teléfono con el que las hiciste.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }

        if (STEP_AWAITING.equals(step)) {
            Contact c = tryParseContact(userInput);
            if (c == null) {
                return OutboundMessage.builder()
                    .text("No reconozco un email o teléfono válido. Ejemplo: nombre@correo.com o 099123456.")
                    .conversationId(convId)
                    .tenantId(tenantId)
                    .build();
            }
            return finishWithQuery(convId, tenantId, c);
        }

        return null;
    }

    private OutboundMessage finishWithQuery(String convId, String tenantId, Contact contact) {
        conversationRepository.clearIntent(convId);
        List<BookingRow> rows = findFutureBookings(tenantId, contact);
        if (rows.isEmpty()) {
            return OutboundMessage.builder()
                .text("No encontré reservas próximas asociadas a ese contacto. Si usaste otro email o teléfono, probá con ese.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }
        StringBuilder sb = new StringBuilder("Estas son tus próximas reservas:\n\n");
        for (BookingRow r : rows) {
            sb.append("• ").append(FMT.format(r.start())).append(" — ").append(r.serviceName());
            sb.append(" (").append(r.businessName()).append(")\n");
            sb.append("  Estado: ").append(translateEstado(r.estado())).append("\n");
        }
        return OutboundMessage.builder()
            .text(sb.toString().trim())
            .conversationId(convId)
            .tenantId(tenantId)
            .build();
    }

    private static String translateEstado(String e) {
        if (e == null) {
            return "—";
        }
        return switch (e) {
            case "PENDING" -> "pendiente de confirmación";
            case "CONFIRMED" -> "confirmada";
            case "CANCELLED" -> "cancelada";
            case "COMPLETED" -> "completada";
            case "NO_SHOW" -> "no asistió";
            default -> e;
        };
    }

    List<BookingRow> findFutureBookings(String tenantId, Contact contact) {
        if (contact.email != null) {
            String sql = BASE_SQL + " AND LOWER(u.email) = LOWER(?) ORDER BY b.fecha_hora_inicio ASC LIMIT 20";
            return jdbcTemplate.query(sql,
                ps -> {
                    ps.setString(1, tenantId);
                    ps.setString(2, contact.email);
                },
                (rs, rowNum) -> mapRow(rs));
        }
        String sql = BASE_SQL
            + " AND regexp_replace(coalesce(u.telefono,''), '[^0-9+]', '', 'g') = ? "
            + "ORDER BY b.fecha_hora_inicio ASC LIMIT 20";
        return jdbcTemplate.query(sql,
            ps -> {
                ps.setString(1, tenantId);
                ps.setString(2, contact.phoneNormalized);
            },
            (rs, rowNum) -> mapRow(rs));
    }

    private static BookingRow mapRow(ResultSet rs) throws SQLException {
        return new BookingRow(
            rs.getTimestamp("fecha_hora_inicio").toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime(),
            rs.getString("estado"),
            rs.getString("svc"),
            rs.getString("bname")
        );
    }

    static Contact tryParseContact(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String text = raw.strip();
        Matcher em = EMAIL.matcher(text);
        if (em.find()) {
            return new Contact(em.group().toLowerCase(Locale.ROOT), null);
        }
        Matcher pm = PHONE_DIGITS.matcher(text.replace(" ", ""));
        if (pm.find()) {
            String digits = normalizePhone(pm.group());
            if (digits.length() >= 7) {
                return new Contact(null, digits);
            }
        }
        if (text.contains("@")) {
            return null;
        }
        String onlyDigits = normalizePhone(text);
        if (onlyDigits.length() >= 7) {
            return new Contact(null, onlyDigits);
        }
        return null;
    }

    private static String normalizePhone(String s) {
        return s.replaceAll("[^0-9+]", "");
    }

    static final class Contact {
        final String email;
        final String phoneNormalized;

        Contact(String email, String phoneNormalized) {
            this.email = email;
            this.phoneNormalized = phoneNormalized;
        }
    }

    record BookingRow(LocalDateTime start, String estado, String serviceName, String businessName) {}
}

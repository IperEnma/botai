package com.botai.application.chatbot.service.action;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppAdapter;
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
 * Lista citas futuras del módulo Agenda por teléfono del cliente.
 * En WhatsApp confía en el número del canal ({@code userId}) sin OTP.
 * Otros canales: pide el teléfono con el que reservó.
 */
@Component
public class ViewAgendaBookingsByContactAction implements BotAction {

    public static final String ACTION_ID = "view_agenda_bookings_by_contact";
    private static final String CTX_STEP = "agendaBookingsContactStep";
    private static final String STEP_AWAITING = "awaiting_phone";

    private static final Pattern PHONE_DIGITS = Pattern.compile("(\\+?\\d[\\d\\s.-]{6,}\\d)");

    private static final DateTimeFormatter FMT =
        DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale.forLanguageTag("es-AR"));

    private static final String BASE_SQL = """
        SELECT b.fecha_hora_inicio, b.estado, s.nombre AS svc, bus.nombre AS bname, u.telefono AS tel
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

        if (step == null) {
            Contact channelPhone = contactFromWhatsAppChannel(state);
            if (channelPhone != null) {
                return finishWithQuery(convId, tenantId, channelPhone);
            }
            Contact fromText = tryParsePhone(userInput);
            if (fromText != null) {
                return finishWithQuery(convId, tenantId, fromText);
            }
            ctx.put(CTX_STEP, STEP_AWAITING);
            conversationRepository.save(ConversationState.builder()
                .conversationId(convId)
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(ACTION_ID)
                .context(ctx)
                .build());
            String cc = AgendaPhoneNormalizer.defaultCountryCode();
            return OutboundMessage.builder()
                .text("Para buscar tus reservas pendientes, indicame el teléfono con el que reservaste.\n"
                    + "Ejemplo: 099 123 456 o +" + cc + " 99 123 456.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }

        if (STEP_AWAITING.equals(step)) {
            Contact fromText = tryParsePhone(userInput);
            if (fromText == null) {
                String cc = AgendaPhoneNormalizer.defaultCountryCode();
                return OutboundMessage.builder()
                    .text("No reconozco un teléfono válido. Ejemplo: 099 123 456 o +" + cc + " 99 123 456.")
                    .conversationId(convId)
                    .tenantId(tenantId)
                    .build();
            }
            return finishWithQuery(convId, tenantId, fromText);
        }

        return null;
    }

    private OutboundMessage finishWithQuery(String convId, String tenantId, Contact contact) {
        conversationRepository.clearIntent(convId);
        List<BookingRow> rows = findFutureBookingsByPhone(tenantId, contact.phoneNormalized());
        if (rows.isEmpty()) {
            return OutboundMessage.builder()
                .text("No encontré reservas pendientes con ese teléfono. "
                    + "Si reservaste con otro número, probá indicándolo.")
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

    List<BookingRow> findFutureBookingsByPhone(String tenantId, String phoneNormalized) {
        if (phoneNormalized == null || phoneNormalized.isBlank()) {
            return List.of();
        }
        String sql = BASE_SQL
            + " AND u.telefono IS NOT NULL AND trim(u.telefono) <> '' "
            + "ORDER BY b.fecha_hora_inicio ASC LIMIT 80";
        return jdbcTemplate.query(sql,
            ps -> ps.setString(1, tenantId),
            (rs, rowNum) -> mapRowWithPhone(rs))
            .stream()
            .filter(row -> AgendaPhoneNormalizer.phonesMatch(row.clientPhone(), phoneNormalized))
            .limit(20)
            .map(BookingRowWithPhone::toBookingRow)
            .toList();
    }

    private static BookingRowWithPhone mapRowWithPhone(ResultSet rs) throws SQLException {
        return new BookingRowWithPhone(
            rs.getTimestamp("fecha_hora_inicio").toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime(),
            rs.getString("estado"),
            rs.getString("svc"),
            rs.getString("bname"),
            rs.getString("tel")
        );
    }

    public static Contact contactFromWhatsAppChannel(ConversationState state) {
        if (state == null) {
            return null;
        }
        if (!WhatsAppAdapter.CHANNEL_ID.equalsIgnoreCase(state.getChannelId())) {
            return null;
        }
        String uid = state.getUserId();
        if (uid == null || uid.isBlank() || "unknown".equalsIgnoreCase(uid.strip())) {
            return null;
        }
        String digits = AgendaPhoneNormalizer.normalize(uid);
        if (!AgendaPhoneNormalizer.isValid(digits)) {
            return null;
        }
        return new Contact(digits);
    }

    static Contact tryParsePhone(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String text = raw.strip();
        Matcher pm = PHONE_DIGITS.matcher(text.replace(" ", ""));
        if (pm.find()) {
            String digits = AgendaPhoneNormalizer.normalize(pm.group());
            if (AgendaPhoneNormalizer.isValid(digits)) {
                return new Contact(digits);
            }
        }
        if (text.contains("@")) {
            return null;
        }
        String digits = AgendaPhoneNormalizer.normalize(text);
        if (AgendaPhoneNormalizer.isValid(digits)) {
            return new Contact(digits);
        }
        return null;
    }

    record Contact(String phoneNormalized) {}

    record BookingRow(LocalDateTime start, String estado, String serviceName, String businessName) {}

    record BookingRowWithPhone(LocalDateTime start, String estado, String serviceName, String businessName,
                               String clientPhone) {
        BookingRow toBookingRow() {
            return new BookingRow(start, estado, serviceName, businessName);
        }
    }
}

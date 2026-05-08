package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Devuelve el vínculo público de agenda (frontend /#/agenda/&lt;slug&gt;) para autogestión del cliente.
 * Lee {@code agenda_businesses} vía JDBC (sin imports del módulo agenda).
 */
@Component
public class GetAgendaPublicUrlAction implements BotAction {

    public static final String ACTION_ID = "get_agenda_public_url";

    private final ConversationRepository conversationRepository;
    private final JdbcTemplate jdbcTemplate;
    private final String frontendBaseUrl;

    public GetAgendaPublicUrlAction(ConversationRepository conversationRepository,
                                    JdbcTemplate jdbcTemplate,
                                    @Value("${agenda.public.base-url:http://localhost:5173}") String frontendBaseUrl) {
        this.conversationRepository = conversationRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.frontendBaseUrl = frontendBaseUrl != null ? frontendBaseUrl.strip() : "http://localhost:5173";
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public String getTriggerIntent() {
        return null;
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String tenantId = state.getContextValue(ConversationContextKeys.TENANT_ID, String.class);
        if (tenantId == null || tenantId.isBlank()) {
            return OutboundMessage.builder()
                .text("No se pudo identificar el negocio.")
                .conversationId(state.getConversationId())
                .tenantId("")
                .build();
        }
        conversationRepository.clearIntent(state.getConversationId());

        Optional<String> slugOpt = findPrimaryPublicSlug(tenantId);
        if (slugOpt.isEmpty() || slugOpt.get().isBlank()) {
            return OutboundMessage.builder()
                .text("Todavía no hay un enlace público de agenda disponible para este negocio. Cuando esté listo, podrás reservar desde la web.")
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }
        String url = buildPublicUrl(slugOpt.get());
        String text = "¡Claro! Podés elegir día y horario y dejar tus datos en nuestra agenda online:\n" + url
            + "\n\nSi tenés alguna duda antes de reservar, escribime.";
        return OutboundMessage.builder()
            .text(text)
            .conversationId(state.getConversationId())
            .tenantId(tenantId)
            .build();
    }

    Optional<String> findPrimaryPublicSlug(String tenantId) {
        List<String> rows = jdbcTemplate.query(
            """
                SELECT public_slug FROM agenda_businesses
                WHERE tenant_id = ? AND deleted_at IS NULL AND activo = TRUE
                  AND public_slug IS NOT NULL AND public_slug <> ''
                ORDER BY created_at ASC
                LIMIT 1
                """,
            ps -> ps.setString(1, tenantId),
            (rs, rowNum) -> rs.getString(1));
        if (rows.isEmpty()) {
            return Optional.empty();
        }
        return Optional.ofNullable(rows.get(0));
    }

    private String buildPublicUrl(String slug) {
        String base = frontendBaseUrl.endsWith("/") ? frontendBaseUrl.substring(0, frontendBaseUrl.length() - 1) : frontendBaseUrl;
        return base + "/#/agenda/" + slug;
    }
}

package com.botai.application.chatbot.service.action;

import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;
import com.botai.infrastructure.config.AppUrlProperties;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Devuelve el vínculo público de agenda (frontend /#/reservar/...) para autogestión del cliente.
 * Lee {@code agenda_businesses} vía JDBC (sin imports del módulo agenda).
 */
@Component
public class GetAgendaPublicUrlAction implements BotAction {

    public static final String ACTION_ID = "get_agenda_public_url";

    private final ConversationRepository conversationRepository;
    private final JdbcTemplate jdbcTemplate;
    private final AppUrlProperties appUrls;

    public GetAgendaPublicUrlAction(ConversationRepository conversationRepository,
                                    JdbcTemplate jdbcTemplate,
                                    AppUrlProperties appUrls) {
        this.conversationRepository = conversationRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.appUrls = appUrls;
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

        Optional<PublicLinkRow> linkOpt = findPrimaryPublicLink(tenantId);
        if (linkOpt.isEmpty()) {
            return OutboundMessage.builder()
                .text("Todavía no hay un enlace público de agenda disponible para este negocio. Cuando esté listo, podrás reservar desde la web.")
                .conversationId(state.getConversationId())
                .tenantId(tenantId)
                .build();
        }
        PublicLinkRow link = linkOpt.get();
        String url = buildPublicUrl(link);
        String text = "¡Genial! Para elegir día, horario disponible y dejar tus datos con calma, entrá acá:\n" + url
            + "\n\nAhí ves la disponibilidad al día. Si antes querés info del negocio (servicios, horarios, etc.), escribime.";
        return OutboundMessage.builder()
            .text(text)
            .conversationId(state.getConversationId())
            .tenantId(tenantId)
            .build();
    }

    Optional<PublicLinkRow> findPrimaryPublicLink(String tenantId) {
        List<PublicLinkRow> rows = jdbcTemplate.query(
            """
                SELECT public_slug, company_slug, nombre,
                       (SELECT COUNT(*) FROM agenda_businesses b2
                         WHERE b2.tenant_id = ? AND b2.deleted_at IS NULL AND b2.activo = TRUE) AS branch_count
                FROM agenda_businesses
                WHERE tenant_id = ? AND deleted_at IS NULL AND activo = TRUE
                  AND public_slug IS NOT NULL AND public_slug <> ''
                ORDER BY created_at ASC
                LIMIT 1
                """,
            ps -> {
                ps.setString(1, tenantId);
                ps.setString(2, tenantId);
            },
            (rs, rowNum) -> new PublicLinkRow(
                rs.getString("public_slug"),
                rs.getString("company_slug"),
                rs.getString("nombre"),
                rs.getLong("branch_count")
            ));
        if (rows.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(rows.get(0));
    }

    private String buildPublicUrl(PublicLinkRow link) {
        String base = appUrls.normalizedFrontend();
        if (link.branchCount() > 1) {
            String company = link.companySlug();
            if (company == null || company.isBlank()) {
                company = compactSlug(link.nombre());
            }
            return base + "/#/reservar?company=" + company;
        }
        return base + "/#/reservar/" + link.publicSlug();
    }

    record PublicLinkRow(String publicSlug, String companySlug, String nombre, long branchCount) {
    }

    private static String compactSlug(String raw) {
        if (raw == null || raw.isBlank()) {
            return "agenda";
        }
        String normalized = java.text.Normalizer.normalize(raw, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(java.util.Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "");
        return normalized.isBlank() ? "agenda" : normalized;
    }
}

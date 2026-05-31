package com.botai.application.chatbot.service.agenda;

import com.botai.infrastructure.config.AppUrlProperties;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.text.Normalizer;

/**
 * Resuelve el enlace público de reserva Agenda por tenant (JDBC, sin imports del módulo agenda).
 */
@Component
public class PublicAgendaLinkResolver {

    private final JdbcTemplate jdbcTemplate;
    private final AppUrlProperties appUrls;

    public PublicAgendaLinkResolver(JdbcTemplate jdbcTemplate, AppUrlProperties appUrls) {
        this.jdbcTemplate = jdbcTemplate;
        this.appUrls = appUrls;
    }

    public Optional<String> findPublicUrl(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return Optional.empty();
        }
        return findPrimaryPublicLink(tenantId).map(this::buildPublicUrl);
    }

    public String buildBookingReply(String url) {
        return "¡Genial! Para elegir día, horario disponible y dejar tus datos con calma, entrá acá:\n" + url
            + "\n\nAhí ves la disponibilidad al día. Si antes querés info del negocio (servicios, horarios, etc.), escribime.";
    }

    public Optional<String> buildBookingReplyForTenant(String tenantId) {
        return findPublicUrl(tenantId).map(this::buildBookingReply);
    }

    public String noLinkMessage() {
        return "Todavía no hay un enlace público de agenda disponible para este negocio. Cuando esté listo, podrás reservar desde la web.";
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

    /**
     * URL pública de reserva para una sucursal (misma lógica que WhatsApp / panel).
     */
    public Optional<String> buildPublicUrlForBranch(String publicSlug, String companySlug, String nombre,
                                                    long activeBranchCount) {
        if (publicSlug == null || publicSlug.isBlank()) {
            return Optional.empty();
        }
        return Optional.of(buildPublicUrl(publicSlug.strip(), companySlug, nombre, activeBranchCount));
    }

    public String buildPublicUrl(String publicSlug, String companySlug, String nombre, long activeBranchCount) {
        String base = appUrls.normalizedFrontend();
        if (activeBranchCount > 1) {
            String company = companySlug;
            if (company == null || company.isBlank()) {
                company = compactSlug(nombre);
            }
            return base + "/#/reservar?company=" + company;
        }
        return base + "/#/reservar/" + publicSlug;
    }

    private String buildPublicUrl(PublicLinkRow link) {
        return buildPublicUrl(link.publicSlug(), link.companySlug(), link.nombre(), link.branchCount());
    }

    record PublicLinkRow(String publicSlug, String companySlug, String nombre, long branchCount) {
    }

    private static String compactSlug(String raw) {
        if (raw == null || raw.isBlank()) {
            return "agenda";
        }
        String normalized = Normalizer.normalize(raw, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.ROOT)
            .replaceAll("[^a-z0-9]+", "");
        return normalized.isBlank() ? "agenda" : normalized;
    }
}

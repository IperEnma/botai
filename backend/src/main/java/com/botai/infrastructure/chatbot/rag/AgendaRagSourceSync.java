package com.botai.infrastructure.chatbot.rag;

import com.botai.application.chatbot.service.agenda.AgendaHorarioTextService;
import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.infrastructure.chatbot.persistence.entity.KnowledgeChunkEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.KnowledgeChunkJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataAccessException;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Materializa conocimiento del módulo Agenda en {@code knowledge_chunk} para RAG (sin imports agenda).
 */
@Component
public class AgendaRagSourceSync {

    private static final Logger log = LoggerFactory.getLogger(AgendaRagSourceSync.class);

    private static final String TOPIC_NEGOCIO = "Agenda: Información del negocio";
    private static final String TOPIC_SERVICIOS = "Agenda: Servicios";
    private static final String TOPIC_HORARIOS = "Agenda: Horarios";
    private static final String TOPIC_POLITICAS = "Agenda: Políticas";
    /** Mejora recuperación por texto cuando no hay embedding. */
    private static final String KEYWORDS_HORARIOS =
        "horario, horarios, abren, cierran, apertura, cierre, atencion, cuando atienden, que hora abren, hasta que hora";

    private final KnowledgeChunkJpaRepository knowledgeChunkJpaRepository;
    private final JdbcTemplate jdbcTemplate;
    private final PublicAgendaLinkResolver publicAgendaLinkResolver;
    private final AgendaHorarioTextService agendaHorarioTextService;
    private final KnowledgeChunkEmbeddingSync embeddingSync;
    private final KnowledgeChunkEmbeddingClearer embeddingClearer;

    public AgendaRagSourceSync(KnowledgeChunkJpaRepository knowledgeChunkJpaRepository,
                               JdbcTemplate jdbcTemplate,
                               PublicAgendaLinkResolver publicAgendaLinkResolver,
                               AgendaHorarioTextService agendaHorarioTextService,
                               KnowledgeChunkEmbeddingClearer embeddingClearer,
                               @Autowired(required = false) KnowledgeChunkEmbeddingSync embeddingSync) {
        this.knowledgeChunkJpaRepository = knowledgeChunkJpaRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.publicAgendaLinkResolver = publicAgendaLinkResolver;
        this.agendaHorarioTextService = agendaHorarioTextService;
        this.embeddingClearer = embeddingClearer;
        this.embeddingSync = embeddingSync;
    }

    @Order(Ordered.LOWEST_PRECEDENCE)
    @EventListener(ApplicationReadyEvent.class)
    @Transactional(noRollbackFor = DataAccessException.class)
    public void syncAgendaIntoChunks() {
        try {
            Set<String> tenantIds = loadAgendaTenantIds();
            if (tenantIds.isEmpty()) {
                log.info("[AGENDA-RAG-SYNC] Sin tenants con negocios agenda; nada que sincronizar");
                return;
            }
            log.info("[AGENDA-RAG-SYNC] Sincronizando chunks agenda para {} tenant(s)", tenantIds.size());
            for (String tenantId : tenantIds) {
                refreshForTenant(tenantId);
            }
            if (embeddingSync != null) {
                int filled = embeddingSync.syncPendingEmbeddings();
                long pending = embeddingSync.countPendingEmbeddings();
                if (filled > 0) {
                    log.info("[AGENDA-RAG-SYNC] {} embedding(s) generados tras sync agenda (pendientes={})",
                            filled, pending);
                } else if (pending > 0) {
                    log.error("[AGENDA-RAG-SYNC] {} chunk(s) activos sin vector tras sync. "
                            + "RAG no encontrará contexto hasta que OpenRouter genere embeddings "
                            + "(revisá OPENROUTER_API_KEY y cuota del modelo de embeddings).",
                            pending);
                }
            }
        } catch (DataAccessException e) {
            log.warn("[AGENDA-RAG-SYNC] Omitido (¿tablas agenda no disponibles?): {}", e.getMessage());
        }
    }

    @Transactional
    public void refreshForTenant(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return;
        }
        List<BusinessRow> businesses = loadActiveBusinesses(tenantId);
        if (businesses.isEmpty()) {
            log.debug("[AGENDA-RAG-SYNC] tenant {} sin negocio activo", tenantId);
            deactivateStaleAgendaChunks(tenantId, Set.of());
            return;
        }
        Set<UUID> keepIds = businesses.stream().map(BusinessRow::id).collect(Collectors.toCollection(LinkedHashSet::new));
        int branchCount = businesses.size();
        String tenantCompanySlug = resolveTenantCompanySlug(businesses);
        for (BusinessRow b : businesses) {
            upsertChunk(tenantId, b.id(), TOPIC_NEGOCIO, buildNegocioContent(tenantId, b, branchCount, tenantCompanySlug), null);
            upsertChunk(tenantId, b.id(), TOPIC_SERVICIOS, buildServiciosContent(b.id()), null);
            upsertChunk(tenantId, b.id(), TOPIC_HORARIOS, buildHorariosContent(b.id()), KEYWORDS_HORARIOS);
            upsertChunk(tenantId, b.id(), TOPIC_POLITICAS, buildPoliticasContent(b.id()), null);
        }
        deactivateStaleAgendaChunks(tenantId, keepIds);
    }

    private Set<String> loadAgendaTenantIds() {
        List<String> list = jdbcTemplate.query(
            "SELECT DISTINCT tenant_id FROM agenda_businesses WHERE deleted_at IS NULL AND activo = TRUE",
            (rs, n) -> rs.getString(1));
        return new LinkedHashSet<>(list);
    }

    private List<BusinessRow> loadActiveBusinesses(String tenantId) {
        return jdbcTemplate.query(
            """
                SELECT id, nombre, descripcion, logo_url, color_primario, public_slug, company_slug, direccion
                FROM agenda_businesses
                WHERE tenant_id = ? AND deleted_at IS NULL AND activo = TRUE
                ORDER BY created_at ASC
                """,
            ps -> ps.setString(1, tenantId),
            (rs, rowNum) -> mapBusiness(rs));
    }

    private static BusinessRow mapBusiness(ResultSet rs) throws SQLException {
        return new BusinessRow(
            rs.getObject("id", UUID.class),
            rs.getString("nombre"),
            rs.getString("descripcion"),
            rs.getString("logo_url"),
            rs.getString("color_primario"),
            rs.getString("public_slug"),
            rs.getString("company_slug"),
            rs.getString("direccion")
        );
    }

    private static String resolveTenantCompanySlug(List<BusinessRow> businesses) {
        for (BusinessRow b : businesses) {
            if (b.companySlug() != null && !b.companySlug().isBlank()) {
                return b.companySlug().strip();
            }
        }
        return null;
    }

    /**
     * Contenido indexable para RAG: nombre comercial y enlace de reserva desde Agenda / {@code bot}.
     */
    static String buildNegocioKnowledgeContent(String displayName, String descripcion, String direccion,
                                               String publicSlug, String publicBookingUrl, String logoUrl,
                                               String colorPrimario) {
        List<String> lines = new ArrayList<>();
        String name = displayName != null ? displayName.strip() : "";
        if (!name.isEmpty()) {
            lines.add("Nombre comercial del negocio: " + name);
            lines.add("El negocio se llama " + name + ". Usa este nombre al hablar con clientes.");
        } else {
            lines.add("Nombre comercial del negocio: (sin nombre cargado en agenda ni en el bot)");
        }
        if (descripcion != null && !descripcion.isBlank()) {
            lines.add("Descripción: " + descripcion.strip());
        }
        if (direccion != null && !direccion.isBlank()) {
            lines.add("Dirección / ubicación del consultorio: " + direccion.strip());
            lines.add("Para indicar dónde queda el local, usa esta dirección.");
        }
        if (publicSlug != null && !publicSlug.isBlank()) {
            lines.add("Identificador público (slug): " + publicSlug.strip());
        }
        if (publicBookingUrl != null && !publicBookingUrl.isBlank()) {
            lines.add("Enlace oficial para reservar cita nueva: " + publicBookingUrl.strip());
            lines.add("Para agendar o reservar, compartir este enlace con el cliente.");
        }
        if (logoUrl != null && !logoUrl.isBlank()) {
            lines.add("Logo: " + logoUrl.strip());
        }
        if (colorPrimario != null && !colorPrimario.isBlank()) {
            lines.add("Color corporativo: " + colorPrimario.strip());
        }
        return String.join("\n", lines);
    }

    private String buildNegocioContent(String tenantId, BusinessRow b, int branchCount, String tenantCompanySlug) {
        String displayName = resolveBusinessDisplayName(tenantId, b.nombre());
        String bookingUrl = publicAgendaLinkResolver
            .buildPublicUrlForBranch(b.publicSlug(), tenantCompanySlug, displayName, branchCount)
            .orElse(null);
        return buildNegocioKnowledgeContent(
            displayName, b.descripcion(), b.direccion(), b.publicSlug(), bookingUrl, b.logoUrl(), b.colorPrimario());
    }

    private String resolveBusinessDisplayName(String tenantId, String agendaNombre) {
        if (agendaNombre != null && !agendaNombre.isBlank()) {
            return agendaNombre.strip();
        }
        if (tenantId == null || tenantId.isBlank()) {
            return "";
        }
        List<String> fromBot = jdbcTemplate.query(
            "SELECT name FROM bot WHERE tenant_id = ? LIMIT 1",
            ps -> ps.setString(1, tenantId),
            (rs, rowNum) -> rs.getString(1));
        if (!fromBot.isEmpty() && fromBot.get(0) != null && !fromBot.get(0).isBlank()) {
            return fromBot.get(0).strip();
        }
        return "";
    }

    private String buildServiciosContent(UUID businessId) {
        List<String> lines = jdbcTemplate.query(
            """
                SELECT nombre, descripcion, duracion_min, precio
                FROM agenda_services
                WHERE business_id = ? AND deleted_at IS NULL AND activo = TRUE
                ORDER BY nombre ASC
                """,
            ps -> ps.setObject(1, businessId),
            (rs, n) -> formatServiceLine(rs));
        if (lines.isEmpty()) {
            return "No hay servicios configurados en la agenda.";
        }
        return String.join("\n", lines);
    }

    private static String formatServiceLine(ResultSet rs) throws SQLException {
        String nombre = rs.getString("nombre");
        int dur = rs.getInt("duracion_min");
        BigDecimal precio = rs.getBigDecimal("precio");
        String desc = rs.getString("descripcion");
        StringBuilder sb = new StringBuilder();
        sb.append("- ").append(nombre).append(": ").append(dur).append(" min");
        if (precio != null) {
            sb.append(", precio ").append(precio.stripTrailingZeros().toPlainString());
        }
        if (desc != null && !desc.isBlank()) {
            sb.append(". ").append(desc.strip());
        }
        return sb.toString();
    }

    private String buildHorariosContent(UUID businessId) {
        return agendaHorarioTextService.formatHorarioForBusiness(businessId)
            .orElse("No hay horarios cargados en la agenda para este negocio.");
    }

    private String buildPoliticasContent(UUID businessId) {
        List<Integer> hoursList = jdbcTemplate.query(
            "SELECT hours_cancellation_limit FROM agenda_business_settings WHERE business_id = ?",
            ps -> ps.setObject(1, businessId),
            (rs, n) -> rs.getInt(1));
        if (hoursList.isEmpty()) {
            return "Políticas: usar reglas estándar del negocio; consultar cancelación con el equipo.";
        }
        int hours = hoursList.get(0);
        return "Cancelación: se recomienda avisar con al menos " + hours + " horas de anticipación (configuración de agenda).";
    }

    /**
     * Desactiva filas Agenda obsoletas (sucursal borrada o desactivada) para no mezclar con el catálogo actual.
     */
    private void deactivateStaleAgendaChunks(String tenantId, Set<UUID> keepBusinessIds) {
        if (tenantId == null || tenantId.isBlank()) {
            return;
        }
        if (keepBusinessIds.isEmpty()) {
            int n = jdbcTemplate.update(
                """
                    UPDATE knowledge_chunk SET active = false
                    WHERE tenant_id = ? AND business_id IS NOT NULL AND topic LIKE 'Agenda:%'
                    """,
                tenantId);
            if (n > 0) {
                log.info("[AGENDA-RAG-SYNC] tenant={}: {} chunk(s) Agenda desactivados (sin sucursales activas)", tenantId, n);
            }
            return;
        }
        String placeholders = String.join(",", Collections.nCopies(keepBusinessIds.size(), "?"));
        List<Object> args = new ArrayList<>();
        args.add(tenantId);
        args.addAll(keepBusinessIds);
        int n = jdbcTemplate.update(
            """
                UPDATE knowledge_chunk SET active = false
                WHERE tenant_id = ? AND business_id IS NOT NULL AND topic LIKE 'Agenda:%'
                AND business_id NOT IN ("""
                + placeholders
                + ")",
            args.toArray());
        if (n > 0) {
            log.info("[AGENDA-RAG-SYNC] tenant={}: {} chunk(s) Agenda desactivados (sucursales eliminadas)", tenantId, n);
        }
    }

    private void upsertChunk(String tenantId, UUID businessId, String topic, String content, String keywords) {
        KnowledgeChunkEntity chunk = knowledgeChunkJpaRepository
            .findByTenantIdAndTopicAndBusinessId(tenantId, topic, businessId)
            .orElseGet(() -> {
                KnowledgeChunkEntity e = new KnowledgeChunkEntity();
                e.setTenantId(tenantId);
                e.setBusinessId(businessId);
                e.setTopic(topic);
                e.setActive(true);
                return e;
            });
        boolean contentChanged = !Objects.equals(content, chunk.getContent());
        boolean keywordsChanged = !Objects.equals(keywords, chunk.getKeywords());
        boolean isNew = chunk.getId() == null;
        chunk.setContent(content);
        chunk.setKeywords(keywords);
        chunk.setActive(true);
        chunk.setBusinessId(businessId);
        knowledgeChunkJpaRepository.save(chunk);
        if (contentChanged && chunk.getId() != null) {
            embeddingClearer.clearEmbeddingForChunk(chunk.getId());
            log.info("[AGENDA-RAG-SYNC] Chunk tenant={} businessId={} topic='{}' id={} contenido actualizado, vector invalidado",
                tenantId, businessId, topic, chunk.getId());
            if (TOPIC_HORARIOS.equals(topic)) {
                log.info("[AGENDA-RAG-SYNC] Horarios tenant={} businessId={}: {}",
                    tenantId, businessId, horariosLogSummary(content));
            }
        } else if (keywordsChanged && chunk.getId() != null) {
            log.debug("[AGENDA-RAG-SYNC] Chunk tenant={} topic='{}' id={} keywords actualizados",
                tenantId, topic, chunk.getId());
        } else if (isNew) {
            log.info("[AGENDA-RAG-SYNC] Chunk creado tenant={} businessId={} topic='{}' id={}",
                tenantId, businessId, topic, chunk.getId());
        }
    }

    private static String horariosLogSummary(String content) {
        if (content == null || content.isBlank()) {
            return "(vacío)";
        }
        int nl = content.indexOf('\n');
        String first = nl >= 0 ? content.substring(0, nl) : content;
        if (content.contains("Resumen:")) {
            int rs = content.lastIndexOf("Resumen:");
            return first + " | " + content.substring(rs).strip();
        }
        return first.strip();
    }

    private record BusinessRow(UUID id, String nombre, String descripcion, String logoUrl, String colorPrimario,
                               String publicSlug, String companySlug, String direccion) {}
}

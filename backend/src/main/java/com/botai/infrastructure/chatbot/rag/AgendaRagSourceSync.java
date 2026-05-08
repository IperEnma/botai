package com.botai.infrastructure.chatbot.rag;

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

    /** Mismo convenio que agenda (Lunes = 0 … Domingo = 6). */
    private static final String[] DAY_NAMES_ES =
        {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};

    private final KnowledgeChunkJpaRepository knowledgeChunkJpaRepository;
    private final JdbcTemplate jdbcTemplate;
    private final KnowledgeChunkEmbeddingSync embeddingSync;

    public AgendaRagSourceSync(KnowledgeChunkJpaRepository knowledgeChunkJpaRepository,
                               JdbcTemplate jdbcTemplate,
                               @Autowired(required = false) KnowledgeChunkEmbeddingSync embeddingSync) {
        this.knowledgeChunkJpaRepository = knowledgeChunkJpaRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.embeddingSync = embeddingSync;
    }

    @Order(Ordered.LOWEST_PRECEDENCE)
    @EventListener(ApplicationReadyEvent.class)
    @Transactional
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
                if (filled > 0) {
                    log.info("[AGENDA-RAG-SYNC] {} embedding(s) generados tras sync agenda", filled);
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
        for (BusinessRow b : businesses) {
            upsertChunk(tenantId, b.id(), TOPIC_NEGOCIO, buildNegocioContent(b));
            upsertChunk(tenantId, b.id(), TOPIC_SERVICIOS, buildServiciosContent(b.id()));
            upsertChunk(tenantId, b.id(), TOPIC_HORARIOS, buildHorariosContent(b.id()));
            upsertChunk(tenantId, b.id(), TOPIC_POLITICAS, buildPoliticasContent(b.id()));
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
                SELECT id, nombre, descripcion, logo_url, color_primario, public_slug
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
            rs.getString("public_slug")
        );
    }

    private String buildNegocioContent(BusinessRow b) {
        List<String> lines = new ArrayList<>();
        lines.add("Nombre: " + (b.nombre() != null ? b.nombre() : ""));
        if (b.descripcion() != null && !b.descripcion().isBlank()) {
            lines.add("Descripción: " + b.descripcion().strip());
        }
        if (b.publicSlug() != null && !b.publicSlug().isBlank()) {
            lines.add("Identificador público (slug): " + b.publicSlug());
        }
        if (b.logoUrl() != null && !b.logoUrl().isBlank()) {
            lines.add("Logo: " + b.logoUrl().strip());
        }
        if (b.colorPrimario() != null && !b.colorPrimario().isBlank()) {
            lines.add("Color corporativo: " + b.colorPrimario().strip());
        }
        return String.join("\n", lines);
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
        List<String> lines = jdbcTemplate.query(
            """
                SELECT dia_semana, apertura, cierre, cerrado
                FROM agenda_business_hours
                WHERE business_id = ?
                ORDER BY dia_semana ASC
                """,
            ps -> ps.setObject(1, businessId),
            (rs, n) -> formatHourLine(rs));
        if (lines.isEmpty()) {
            return "No hay horarios cargados en la agenda para este negocio.";
        }
        return String.join("\n", lines);
    }

    private static String formatHourLine(ResultSet rs) throws SQLException {
        int d = rs.getInt("dia_semana");
        String label = (d >= 0 && d <= 6) ? DAY_NAMES_ES[d] : "Día " + d;
        if (rs.getBoolean("cerrado")) {
            return label + ": Cerrado";
        }
        var a = rs.getTime("apertura");
        var c = rs.getTime("cierre");
        if (a == null || c == null) {
            return label + ": Cerrado";
        }
        return label + ": " + a.toLocalTime() + " - " + c.toLocalTime();
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

    private void upsertChunk(String tenantId, UUID businessId, String topic, String content) {
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
        boolean isNew = chunk.getId() == null;
        chunk.setContent(content);
        chunk.setActive(true);
        chunk.setBusinessId(businessId);
        knowledgeChunkJpaRepository.save(chunk);
        if (contentChanged && chunk.getId() != null) {
            jdbcTemplate.update("UPDATE knowledge_chunk SET embedding = NULL WHERE id = ?", chunk.getId());
            log.info("[AGENDA-RAG-SYNC] Chunk tenant={} businessId={} topic='{}' id={} -> embedding=NULL",
                tenantId, businessId, topic, chunk.getId());
        } else if (isNew) {
            log.info("[AGENDA-RAG-SYNC] Chunk creado tenant={} businessId={} topic='{}' id={}",
                tenantId, businessId, topic, chunk.getId());
        }
    }

    private record BusinessRow(UUID id, String nombre, String descripcion, String logoUrl, String colorPrimario, String publicSlug) {}
}

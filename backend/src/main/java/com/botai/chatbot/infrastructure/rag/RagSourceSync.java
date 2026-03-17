package com.botai.chatbot.infrastructure.rag;

import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.entity.KnowledgeChunkEntity;
import com.botai.chatbot.infrastructure.persistence.entity.ServiceEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.KnowledgeChunkJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.ServiceJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Mantiene sincronizados los chunks de RAG (y sus vectores) con horarios, servicios y knowledge.
 * - Al arranque: crea/actualiza chunks de horario y servicios por tenant; luego el sync de embeddings rellena vectores.
 * - Cuando se guardan/borran horarios o servicios: refresca los chunks de ese tenant y borra el vector (embedding = NULL)
 *   para que se regenere en el próximo arranque o en un sync posterior.
 * - Cuando se actualiza/crea un knowledge chunk: borra su vector para que se regenere.
 */
@Component
public class RagSourceSync {

    private static final Logger log = LoggerFactory.getLogger(RagSourceSync.class);
    private static final String TOPIC_HORARIO = "Horario del negocio";
    private static final String TOPIC_SERVICIOS = "Servicios del negocio";
    private static final String[] DAY_NAMES_ES = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};

    private final KnowledgeChunkJpaRepository knowledgeChunkJpaRepository;
    private final BusinessHoursJpaRepository businessHoursRepository;
    private final ServiceJpaRepository serviceRepository;
    private final JdbcTemplate jdbcTemplate;
    private final KnowledgeChunkEmbeddingSync embeddingSync;

    public RagSourceSync(KnowledgeChunkJpaRepository knowledgeChunkJpaRepository,
                         BusinessHoursJpaRepository businessHoursRepository,
                         ServiceJpaRepository serviceRepository,
                         JdbcTemplate jdbcTemplate,
                         @Autowired(required = false) KnowledgeChunkEmbeddingSync embeddingSync) {
        this.knowledgeChunkJpaRepository = knowledgeChunkJpaRepository;
        this.businessHoursRepository = businessHoursRepository;
        this.serviceRepository = serviceRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.embeddingSync = embeddingSync;
    }

    @Order(Ordered.HIGHEST_PRECEDENCE)
    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void syncHorarioAndServiciosIntoChunks() {
        Set<String> tenantIds = new HashSet<>();
        tenantIds.addAll(businessHoursRepository.findDistinctTenantIds());
        tenantIds.addAll(serviceRepository.findDistinctTenantIds());
        if (tenantIds.isEmpty()) {
            log.info("[RAG-SYNC] No hay tenants con horario/servicios; no se crean chunks sintéticos");
            return;
        }
        log.info("[RAG-SYNC] Sincronizando chunks horario/servicios para {} tenant(s): {}", tenantIds.size(), tenantIds);
        for (String tenantId : tenantIds) {
            refreshForTenant(tenantId);
        }
    }

    /**
     * Actualiza los chunks sintéticos (Horario, Servicios) para un tenant y limpia sus vectores
     * para que se regeneren. Llamar tras guardar/borrar horarios o servicios.
     */
    @Transactional
    public void refreshForTenant(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return;
        }
        log.info("[RAG-SYNC] Refrescando chunks para tenant {}", tenantId);
        syncHorarioChunk(tenantId);
        syncServiciosChunk(tenantId);
        if (embeddingSync != null) {
            int filled = embeddingSync.syncPendingEmbeddings();
            if (filled > 0) {
                log.info("[RAG-SYNC] Tenant {}: {} embedding(s) generados para búsqueda semántica", tenantId, filled);
            }
        }
    }

    /**
     * Borra el vector de un chunk (p. ej. knowledge) para que se regenere en el próximo sync.
     * Llamar tras crear o actualizar un knowledge chunk.
     */
    public void clearEmbeddingForChunk(long chunkId) {
        int updated = jdbcTemplate.update("UPDATE knowledge_chunk SET embedding = NULL WHERE id = ?", chunkId);
        if (updated > 0) {
            log.info("[RAG-SYNC] Embedding borrado para chunk id={} (se regenerará en próximo arranque)", chunkId);
        }
    }

    private void syncHorarioChunk(String tenantId) {
        List<BusinessHoursEntity> hours = businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId);
        List<String> lines = new java.util.ArrayList<>();
        for (BusinessHoursEntity h : hours) {
            String open = h.getOpenTime();
            String close = h.getCloseTime();
            boolean hasHours = (open != null && !open.isBlank()) || (close != null && !close.isBlank());
            if (hasHours) {
                int day = h.getDayOfWeek();
                String dayLabel = day >= 1 && day <= 7 ? DAY_NAMES_ES[day - 1] : "Día " + day;
                String slot = (open != null ? open : "?") + " - " + (close != null ? close : "?");
                lines.add(dayLabel + ": " + slot);
            }
        }
        String content = lines.isEmpty()
            ? "No hay horario configurado."
            : String.join("\n", lines);
        upsertChunk(tenantId, TOPIC_HORARIO, content);
    }

    private void syncServiciosChunk(String tenantId) {
        List<ServiceEntity> services = serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId);
        String content = (services == null || services.isEmpty())
            ? "No hay servicios configurados."
            : services.stream().map(ServiceEntity::getName).collect(Collectors.joining(", "));
        upsertChunk(tenantId, TOPIC_SERVICIOS, content);
    }

    private void upsertChunk(String tenantId, String topic, String content) {
        KnowledgeChunkEntity chunk = knowledgeChunkJpaRepository.findByTenantIdAndTopic(tenantId, topic)
            .orElseGet(() -> {
                KnowledgeChunkEntity e = new KnowledgeChunkEntity();
                e.setTenantId(tenantId);
                e.setTopic(topic);
                e.setActive(true);
                return e;
            });
        boolean contentChanged = !content.equals(chunk.getContent());
        boolean isNew = chunk.getId() == null;
        chunk.setContent(content);
        chunk.setActive(true);
        knowledgeChunkJpaRepository.save(chunk);
        if (contentChanged && chunk.getId() != null) {
            jdbcTemplate.update("UPDATE knowledge_chunk SET embedding = NULL WHERE id = ?", chunk.getId());
            log.info("[RAG-SYNC] Chunk actualizado tenantId={} topic='{}' id={} -> embedding=NULL para regenerar", tenantId, topic, chunk.getId());
        } else if (isNew) {
            log.info("[RAG-SYNC] Chunk creado tenantId={} topic='{}' id={}", tenantId, topic, chunk.getId());
        }
    }
}

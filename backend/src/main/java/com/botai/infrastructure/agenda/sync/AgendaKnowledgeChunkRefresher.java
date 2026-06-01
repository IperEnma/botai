package com.botai.infrastructure.agenda.sync;

import com.botai.infrastructure.chatbot.rag.AgendaRagSourceSync;
import com.botai.infrastructure.chatbot.rag.KnowledgeChunkEmbeddingSync;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Tras cambios en negocio, horarios, servicios o políticas de Agenda, actualiza los
 * {@code knowledge_chunk} del tenant (y embeddings pendientes) para que RAG y la pestaña Knowledge del bot los vean sin reiniciar.
 */
@Component
public class AgendaKnowledgeChunkRefresher {

    private static final Logger log = LoggerFactory.getLogger(AgendaKnowledgeChunkRefresher.class);

    private final AgendaRagSourceSync agendaRagSourceSync;
    /** Opcional: solo existe si hay {@code EmbeddingModel} (misma condición que el bean de sync). */
    private final KnowledgeChunkEmbeddingSync embeddingSync;

    public AgendaKnowledgeChunkRefresher(AgendaRagSourceSync agendaRagSourceSync,
                                         @Autowired(required = false) KnowledgeChunkEmbeddingSync embeddingSync) {
        this.agendaRagSourceSync = agendaRagSourceSync;
        this.embeddingSync = embeddingSync;
    }

    public void refreshAfterCatalogChange(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return;
        }
        try {
            agendaRagSourceSync.refreshForTenant(tenantId);
            if (embeddingSync != null) {
                int filled = embeddingSync.syncPendingEmbeddings();
                if (filled > 0) {
                    log.info("[AGENDA-RAG] {} embedding(s) regenerados tras cambio de catálogo (tenant={})", filled, tenantId);
                } else {
                    long pending = embeddingSync.countPendingEmbeddings();
                    if (pending > 0) {
                        log.warn("[AGENDA-RAG] {} chunk(s) sin embedding tras refresh (tenant={}); RAG usará fallback por texto",
                            pending, tenantId);
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[AGENDA-RAG] refresh knowledge_chunk tras cambio de catálogo omitido: {}", e.getMessage());
        }
    }
}

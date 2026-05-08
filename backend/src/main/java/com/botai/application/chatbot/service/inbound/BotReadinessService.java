package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.service.conversation.common.MenuService;

import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaBusinessHoursJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.BusinessJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.chatbot.persistence.jpa.KnowledgeChunkJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Comprueba que el bot cumpla requisitos mínimos antes de responder.
 * - FAQ activa (solo o junto con IA): debe tener al menos un menú.
 * - Solo IA sin FAQ: no se exige menú.
 * - IA activa: horarios o servicios del negocio en Agenda, o al menos un chunk de conocimiento activo (RAG).
 */
@Service
public class BotReadinessService {

    private static final Logger log = LoggerFactory.getLogger(BotReadinessService.class);

    private final FeatureFlagService featureFlagService;
    private final MenuService menuService;
    private final BusinessJpaRepository agendaBusinessRepository;
    private final AgendaBusinessHoursJpaRepository agendaBusinessHoursRepository;
    private final ServiceJpaRepository agendaServiceRepository;
    private final KnowledgeChunkJpaRepository knowledgeRepository;

    public BotReadinessService(FeatureFlagService featureFlagService,
                               MenuService menuService,
                               BusinessJpaRepository agendaBusinessRepository,
                               AgendaBusinessHoursJpaRepository agendaBusinessHoursRepository,
                               ServiceJpaRepository agendaServiceRepository,
                               KnowledgeChunkJpaRepository knowledgeRepository) {
        this.featureFlagService = featureFlagService;
        this.menuService = menuService;
        this.agendaBusinessRepository = agendaBusinessRepository;
        this.agendaBusinessHoursRepository = agendaBusinessHoursRepository;
        this.agendaServiceRepository = agendaServiceRepository;
        this.knowledgeRepository = knowledgeRepository;
    }

    /**
     * Si el bot no está listo para atender, devuelve el mensaje a mostrar. Null = listo.
     */
    public String getNotReadyMessage(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) return null;

        if (featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)
                && !menuService.hasAnyActiveMenu(tenantId)) {
            int menuCount = menuService.countActiveMenusByTenant(tenantId);
            log.warn("[READINESS] FAQ activa pero sin menú. tenantId={}, menús activos={}.", tenantId, menuCount);
            return "El bot no está activo. Con FAQ activada necesitas al menos un menú (pestaña Menús), también si usas IA a la vez.";
        }

        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)
                && !hasMinimumContextForAi(tenantId)) {
            return "El bot no está activo. Para usar la IA configurá horarios o servicios del negocio, o contenido en la base de conocimiento.";
        }

        return null;
    }

    private boolean hasMinimumContextForAi(String tenantId) {
        if (!knowledgeRepository.findByTenantIdAndActiveTrue(tenantId).isEmpty()) {
            return true;
        }
        List<BusinessEntity> businesses = agendaBusinessRepository.findAllByTenantIdAndDeletedAtIsNull(tenantId);
        for (BusinessEntity b : businesses) {
            if (!b.isActivo()) {
                continue;
            }
            var id = b.getId();
            if (!agendaBusinessHoursRepository.findByBusinessId(id).isEmpty()) {
                return true;
            }
            if (!agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(id).isEmpty()) {
                return true;
            }
        }
        return false;
    }
}

package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.service.conversation.common.MenuService;

import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.infrastructure.chatbot.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.infrastructure.chatbot.persistence.jpa.KnowledgeChunkJpaRepository;
import com.botai.infrastructure.chatbot.persistence.jpa.ServiceJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Comprueba que el bot cumpla requisitos mínimos antes de responder.
 * - FAQ activa (solo o junto con IA): debe tener al menos un menú.
 * - Solo IA sin FAQ: no se exige menú.
 * - IA activa: debe tener horario, servicios o base de conocimiento (RAG).
 * No se cargan respuestas ni menús por defecto.
 */
@Service
public class BotReadinessService {

    private static final Logger log = LoggerFactory.getLogger(BotReadinessService.class);

    private final FeatureFlagService featureFlagService;
    private final MenuService menuService;
    private final BusinessHoursJpaRepository businessHoursRepository;
    private final ServiceJpaRepository serviceRepository;
    private final KnowledgeChunkJpaRepository knowledgeRepository;

    public BotReadinessService(FeatureFlagService featureFlagService,
                               MenuService menuService,
                               BusinessHoursJpaRepository businessHoursRepository,
                               ServiceJpaRepository serviceRepository,
                               KnowledgeChunkJpaRepository knowledgeRepository) {
        this.featureFlagService = featureFlagService;
        this.menuService = menuService;
        this.businessHoursRepository = businessHoursRepository;
        this.serviceRepository = serviceRepository;
        this.knowledgeRepository = knowledgeRepository;
    }

    /**
     * Si el bot no está listo para atender, devuelve el mensaje a mostrar. Null = listo.
     */
    public String getNotReadyMessage(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) return null;

        // Menú obligatorio siempre que FAQ esté activa, también si IA está activa a la vez (FAQ+IA).
        if (featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId)
                && !menuService.hasAnyActiveMenu(tenantId)) {
            int menuCount = menuService.countActiveMenusByTenant(tenantId);
            log.warn("[READINESS] FAQ activa pero sin menú. tenantId={}, menús activos={}.", tenantId, menuCount);
            return "El bot no está activo. Con FAQ activada necesitas al menos un menú (pestaña Menús), también si usas IA a la vez.";
        }

        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)
                && !hasMinimumContextForAi(tenantId)) {
            return "El bot no está activo. Para usar la IA configura al menos: horario (pestaña Horario), servicios (pestaña Servicios) o base de conocimiento (pestaña Knowledge).";
        }

        return null;
    }

    private boolean hasMinimumContextForAi(String tenantId) {
        boolean hasHours = !businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId).isEmpty();
        boolean hasServices = !serviceRepository.findByTenantIdAndActiveTrueOrderBySortOrderAsc(tenantId).isEmpty();
        boolean hasKnowledge = !knowledgeRepository.findByTenantIdAndActiveTrue(tenantId).isEmpty();
        return hasHours || hasServices || hasKnowledge;
    }
}

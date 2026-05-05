package com.botai.agenda.infrastructure.config;

import com.botai.agenda.domain.feature.AgendaFeatureFlagService;
import com.botai.agenda.domain.feature.AgendaFeatures;
import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.domain.repository.TenantConfigRepository;
import org.springframework.stereotype.Component;

/**
 * Implementación JPA del sistema de feature flags de AGENDA.
 *
 * <p>Política <b>fail-closed</b>: si no existe configuración para el tenant,
 * {@code AGENDA_ENABLED} se devuelve como {@code false} (los defaults de
 * {@link TenantConfig#defaultsFor(String)} apagan el módulo por defecto).
 * Un admin de plataforma debe hacer un PUT explícito para activar el módulo
 * para un tenant.</p>
 */
@Component
public class JpaAgendaFeatureFlagService implements AgendaFeatureFlagService {

    private final TenantConfigRepository tenantConfigRepository;

    public JpaAgendaFeatureFlagService(TenantConfigRepository tenantConfigRepository) {
        this.tenantConfigRepository = tenantConfigRepository;
    }

    @Override
    public boolean isEnabled(AgendaFeatures feature, String tenantId) {
        if (feature == null || tenantId == null || tenantId.isBlank()) {
            return false;
        }
        TenantConfig config = tenantConfigRepository.findByTenantId(tenantId)
                .orElseGet(() -> TenantConfig.defaultsFor(tenantId));
        return switch (feature) {
            case AGENDA_ENABLED -> config.isAgendaEnabled();
            case PUBLIC_SEARCH_ENABLED -> config.isPublicSearchEnabled();
            case LOYALTY_ENGINE_ENABLED -> config.isLoyaltyEngineEnabled();
            case AUTO_NOTIFICATIONS -> config.isAutoNotifications();
        };
    }
}

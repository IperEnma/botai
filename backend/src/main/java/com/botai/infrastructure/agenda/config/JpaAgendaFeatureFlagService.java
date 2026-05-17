package com.botai.infrastructure.agenda.config;

import com.botai.domain.agenda.feature.AgendaFeatureFlagService;
import com.botai.domain.agenda.feature.AgendaFeatures;
import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import org.springframework.stereotype.Component;

/**
 * Implementación JPA del sistema de feature flags de AGENDA.
 *
 * <p>Para {@code AGENDA_ENABLED}: política <b>fail-open</b> cuando no existe
 * fila en {@code agenda_tenant_config}. Si el {@code TenantAccount} existe
 * (el guard lo verificó antes) pero aún no hay config —p.ej. recién
 * registrado— se asume habilitado. Bloquear sería un falso negativo que
 * impediría el onboarding.</p>
 *
 * <p>Para el resto de flags: se usan los valores de
 * {@link TenantConfig#defaultsFor(String)} cuando no hay fila.</p>
 */
@Component
public class JpaAgendaFeatureFlagService implements AgendaFeatureFlagService {

    private static final org.slf4j.Logger log =
            org.slf4j.LoggerFactory.getLogger(JpaAgendaFeatureFlagService.class);

    private final TenantConfigRepository tenantConfigRepository;

    public JpaAgendaFeatureFlagService(TenantConfigRepository tenantConfigRepository) {
        this.tenantConfigRepository = tenantConfigRepository;
    }

    @Override
    public boolean isEnabled(AgendaFeatures feature, String tenantId) {
        if (feature == null || tenantId == null || tenantId.isBlank()) {
            return false;
        }
        var optConfig = tenantConfigRepository.findByTenantId(tenantId);
        if (optConfig.isEmpty()) {
            if (feature == AgendaFeatures.AGENDA_ENABLED) {
                log.warn("AGENDA: TenantConfig no encontrado para tenantId={} → fail-open en AGENDA_ENABLED", tenantId);
                return true;
            }
            TenantConfig defaults = TenantConfig.defaultsFor(tenantId);
            return switch (feature) {
                case PUBLIC_SEARCH_ENABLED -> defaults.isPublicSearchEnabled();
                case LOYALTY_ENGINE_ENABLED -> defaults.isLoyaltyEngineEnabled();
                case AUTO_NOTIFICATIONS -> defaults.isAutoNotifications();
                default -> false;
            };
        }
        TenantConfig config = optConfig.get();
        return switch (feature) {
            case AGENDA_ENABLED -> config.isAgendaEnabled();
            case PUBLIC_SEARCH_ENABLED -> config.isPublicSearchEnabled();
            case LOYALTY_ENGINE_ENABLED -> config.isLoyaltyEngineEnabled();
            case AUTO_NOTIFICATIONS -> config.isAutoNotifications();
        };
    }
}

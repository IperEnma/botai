package com.botai.application.agenda.usecase.feature;

import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Upsert de la configuración de flags de un tenant.
 * <p>Si no existe, se crea partiendo de {@link TenantConfig#defaultsFor(String)}.
 * Los valores {@code null} se ignoran (semántica PATCH).</p>
 */
@Service
public class UpdateTenantFeaturesUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdateTenantFeaturesUseCase.class);

    private final TenantConfigRepository tenantConfigRepository;

    public UpdateTenantFeaturesUseCase(TenantConfigRepository tenantConfigRepository) {
        this.tenantConfigRepository = tenantConfigRepository;
    }

    @Transactional
    public TenantConfig execute(String tenantId,
                                Boolean agendaEnabled,
                                Boolean publicSearchEnabled,
                                Boolean loyaltyEngineEnabled,
                                Boolean autoNotifications) {
        TenantConfig current = tenantConfigRepository.findByTenantId(tenantId)
                .orElseGet(() -> TenantConfig.defaultsFor(tenantId));

        TenantConfig updated = new TenantConfig(
                tenantId,
                agendaEnabled == null ? current.isAgendaEnabled() : agendaEnabled,
                publicSearchEnabled == null ? current.isPublicSearchEnabled() : publicSearchEnabled,
                loyaltyEngineEnabled == null ? current.isLoyaltyEngineEnabled() : loyaltyEngineEnabled,
                autoNotifications == null ? current.isAutoNotifications() : autoNotifications
        );
        TenantConfig saved = tenantConfigRepository.save(updated);
        log.info("AGENDA: flags actualizados tenant={} agendaEnabled={}", tenantId, saved.isAgendaEnabled());
        return saved;
    }
}

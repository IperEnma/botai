package com.botai.agenda.application.usecase.feature;

import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.domain.repository.TenantConfigRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Lee los flags de un tenant; si no hay registro, devuelve los defaults. */
@Service
public class GetTenantFeaturesUseCase {

    private final TenantConfigRepository tenantConfigRepository;

    public GetTenantFeaturesUseCase(TenantConfigRepository tenantConfigRepository) {
        this.tenantConfigRepository = tenantConfigRepository;
    }

    @Transactional(readOnly = true)
    public TenantConfig execute(String tenantId) {
        return tenantConfigRepository.findByTenantId(tenantId)
                .orElseGet(() -> TenantConfig.defaultsFor(tenantId));
    }
}

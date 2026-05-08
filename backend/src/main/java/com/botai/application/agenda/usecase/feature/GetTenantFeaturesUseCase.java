package com.botai.application.agenda.usecase.feature;

import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.repository.TenantConfigRepository;
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

package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.TenantConfig;

import java.util.Optional;

public interface TenantConfigRepository {

    TenantConfig save(TenantConfig config);

    Optional<TenantConfig> findByTenantId(String tenantId);
}

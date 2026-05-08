package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.TenantConfig;

import java.util.Optional;

public interface TenantConfigRepository {

    TenantConfig save(TenantConfig config);

    Optional<TenantConfig> findByTenantId(String tenantId);
}

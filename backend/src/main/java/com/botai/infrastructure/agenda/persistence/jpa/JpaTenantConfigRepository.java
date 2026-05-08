package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import com.botai.infrastructure.agenda.persistence.entity.TenantConfigEntity;
import com.botai.infrastructure.agenda.persistence.mapper.TenantConfigMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public class JpaTenantConfigRepository implements TenantConfigRepository {

    private final TenantConfigJpaRepository jpa;

    public JpaTenantConfigRepository(TenantConfigJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public TenantConfig save(TenantConfig config) {
        TenantConfigEntity entity = TenantConfigMapper.toEntity(config);
        TenantConfigEntity saved = jpa.save(entity);
        return TenantConfigMapper.toDomain(saved);
    }

    @Override
    public Optional<TenantConfig> findByTenantId(String tenantId) {
        return jpa.findById(tenantId).map(TenantConfigMapper::toDomain);
    }
}

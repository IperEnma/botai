package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import com.botai.infrastructure.agenda.persistence.mapper.BusinessMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaBusinessRepository implements BusinessRepository {

    private final BusinessJpaRepository jpa;

    public JpaBusinessRepository(BusinessJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Business save(Business business) {
        BusinessEntity entity = BusinessMapper.toEntity(business);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        BusinessEntity saved = jpa.save(entity);
        return BusinessMapper.toDomain(saved);
    }

    @Override
    public Optional<Business> findById(UUID id) {
        return jpa.findById(id).map(BusinessMapper::toDomain);
    }

    @Override
    public Optional<Business> findByIdAndTenantId(UUID id, String tenantId) {
        return jpa.findByIdAndTenantIdAndDeletedAtIsNull(id, tenantId)
                .map(BusinessMapper::toDomain);
    }

    @Override
    public List<Business> findAllByTenantId(String tenantId) {
        return jpa.findAllByTenantIdAndDeletedAtIsNull(tenantId).stream()
                .map(BusinessMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Business> findByPublicSlug(String publicSlug) {
        return jpa.findByPublicSlugAndDeletedAtIsNull(publicSlug).map(BusinessMapper::toDomain);
    }

    @Override
    public boolean existsByIdAndTenantId(UUID id, String tenantId) {
        return jpa.existsByIdAndTenantIdAndDeletedAtIsNull(id, tenantId);
    }

    @Override
    @Transactional
    public void softDelete(UUID id) {
        jpa.softDelete(id);
    }
}

package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.exception.BusinessAlreadyLinkedToOtherBotException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;
import com.botai.infrastructure.agenda.persistence.mapper.BusinessMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
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
    public List<Business> findAllActiveByCompanySlug(String companySlug) {
        if (companySlug == null || companySlug.isBlank()) {
            return List.of();
        }
        return jpa.findAllByCompanySlugAndActivoTrueAndDeletedAtIsNullOrderByNombreAsc(companySlug.strip())
                .stream()
                .map(BusinessMapper::toDomain)
                .toList();
    }

    @Override
    public long countActiveByTenantId(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return 0;
        }
        return jpa.countByTenantIdAndActivoTrueAndDeletedAtIsNull(tenantId);
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

    @Override
    @Transactional
    public void replaceBotLinksForWorkspaceBot(String tenantId, long botId, Set<UUID> businessIds) {
        Set<UUID> ids = businessIds == null ? Set.of() : new LinkedHashSet<>(businessIds);
        for (UUID id : ids) {
            if (!jpa.existsByIdAndTenantIdAndDeletedAtIsNull(id, tenantId)) {
                throw new BusinessNotFoundException(id);
            }
        }
        if (!ids.isEmpty()) {
            List<BusinessEntity> conflicts = jpa.findConflictingBotAssignments(tenantId, ids, botId);
            if (!conflicts.isEmpty()) {
                BusinessEntity c = conflicts.get(0);
                throw new BusinessAlreadyLinkedToOtherBotException(c.getId(), c.getBotId());
            }
        }
        if (ids.isEmpty()) {
            jpa.clearAllBotLinksForBotInTenant(tenantId, botId);
            return;
        }
        jpa.clearBotLinksForBotNotInIds(tenantId, botId, ids);
        jpa.setBotIdForBusinessIds(tenantId, botId, ids);
    }
}

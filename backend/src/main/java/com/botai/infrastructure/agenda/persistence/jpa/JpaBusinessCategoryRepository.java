package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.infrastructure.agenda.persistence.entity.BusinessCategoryEntity;
import com.botai.infrastructure.agenda.persistence.entity.BusinessCategoryId;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class JpaBusinessCategoryRepository implements BusinessCategoryRepository {

    private final BusinessCategoryJpaRepository jpa;

    public JpaBusinessCategoryRepository(BusinessCategoryJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public void associate(UUID businessId, UUID categoryId) {
        BusinessCategoryId id = new BusinessCategoryId(businessId, categoryId);
        if (!jpa.existsById(id)) {
            jpa.save(new BusinessCategoryEntity(id));
        }
    }

    @Override
    public void replaceCategories(UUID businessId, List<UUID> categoryIds) {
        jpa.deleteAllByBusinessId(businessId);
        jpa.flush();
        if (categoryIds == null || categoryIds.isEmpty()) {
            return;
        }
        for (UUID categoryId : categoryIds) {
            BusinessCategoryId id = new BusinessCategoryId(businessId, categoryId);
            jpa.save(new BusinessCategoryEntity(id));
        }
    }

    @Override
    public List<UUID> findCategoryIdsByBusinessId(UUID businessId) {
        return jpa.findAllByIdBusinessId(businessId).stream()
                .map(bc -> bc.getId().getCategoryId())
                .toList();
    }

    @Override
    public List<String> findCategorySlugsByBusinessId(UUID businessId) {
        return jpa.findSlugsByBusinessId(businessId);
    }

    @Override
    public List<UUID> findBusinessIdsByCategoryId(UUID categoryId) {
        return jpa.findAllByIdCategoryId(categoryId).stream()
                .map(bc -> bc.getId().getBusinessId())
                .toList();
    }
}

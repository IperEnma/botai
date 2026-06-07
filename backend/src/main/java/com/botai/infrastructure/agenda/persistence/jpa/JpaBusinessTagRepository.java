package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.SearchTag;
import com.botai.domain.agenda.repository.BusinessTagRepository;
import com.botai.infrastructure.agenda.persistence.entity.BusinessTagEntity;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Repository
public class JpaBusinessTagRepository implements BusinessTagRepository {

    private final BusinessTagJpaRepository jpa;
    private final EntityManager entityManager;

    public JpaBusinessTagRepository(BusinessTagJpaRepository jpa, EntityManager entityManager) {
        this.jpa = jpa;
        this.entityManager = entityManager;
    }

    @Override
    public List<SearchTag> findByBusinessId(UUID businessId) {
        if (businessId == null) {
            return List.of();
        }
        return jpa.findByBusinessIdOrderByTypeAscValueAsc(businessId).stream()
                .map(this::toDomain)
                .toList();
    }

    @Override
    public Map<UUID, List<SearchTag>> findByBusinessIds(Collection<UUID> businessIds) {
        if (businessIds == null || businessIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, List<SearchTag>> result = new HashMap<>();
        for (BusinessTagEntity entity : jpa.findByBusinessIdInOrderByBusinessIdAscTypeAscValueAsc(businessIds)) {
            result.computeIfAbsent(entity.getBusinessId(), ignored -> new ArrayList<>())
                    .add(toDomain(entity));
        }
        return result;
    }

    @Override
    @Transactional
    public void replaceByBusinessId(UUID businessId, List<SearchTag> tags) {
        if (businessId == null) {
            return;
        }
        jpa.deleteByBusinessId(businessId);
        entityManager.flush();
        if (tags == null || tags.isEmpty()) {
            return;
        }
        Set<String> seen = new LinkedHashSet<>();
        List<BusinessTagEntity> entities = new ArrayList<>(tags.size());
        for (SearchTag tag : tags) {
            if (tag == null || tag.value() == null || tag.value().isBlank()) {
                continue;
            }
            String dedupeKey = tag.type() + "\0" + tag.value().strip().toLowerCase();
            if (!seen.add(dedupeKey)) {
                continue;
            }
            BusinessTagEntity entity = new BusinessTagEntity();
            entity.setId(UUID.randomUUID());
            entity.setBusinessId(businessId);
            entity.setValue(tag.value().strip());
            entity.setType(tag.type());
            entities.add(entity);
        }
        if (!entities.isEmpty()) {
            jpa.saveAll(entities);
        }
    }

    private SearchTag toDomain(BusinessTagEntity entity) {
        return new SearchTag(entity.getValue(), entity.getType());
    }
}

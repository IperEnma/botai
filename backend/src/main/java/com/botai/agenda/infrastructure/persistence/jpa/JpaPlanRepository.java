package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.repository.PlanRepository;
import com.botai.agenda.infrastructure.persistence.entity.PlanEntity;
import com.botai.agenda.infrastructure.persistence.mapper.PlanMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaPlanRepository implements PlanRepository {

    private final PlanJpaRepository jpa;

    public JpaPlanRepository(PlanJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Plan save(Plan plan) {
        PlanEntity entity = PlanMapper.toEntity(plan);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        PlanEntity saved = jpa.save(entity);
        return PlanMapper.toDomain(saved);
    }

    @Override
    public Optional<Plan> findById(UUID id) {
        return jpa.findByIdAndDeletedAtIsNull(id).map(PlanMapper::toDomain);
    }

    @Override
    public List<Plan> findAllByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessIdAndDeletedAtIsNull(businessId).stream()
                .map(PlanMapper::toDomain)
                .toList();
    }

    @Override
    public List<Plan> findAllActiveByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(businessId).stream()
                .map(PlanMapper::toDomain)
                .toList();
    }

    @Override
    @Transactional
    public void softDelete(UUID id) {
        jpa.softDelete(id);
    }
}

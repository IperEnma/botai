package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.Plan;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link Plan}. Los adapters viven en
 * {@code infrastructure.persistence.jpa}.
 */
public interface PlanRepository {

    Plan save(Plan plan);

    Optional<Plan> findById(UUID id);

    List<Plan> findAllByBusinessId(UUID businessId);

    List<Plan> findAllActiveByBusinessId(UUID businessId);

    void softDelete(UUID id);
}

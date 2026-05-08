package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.Plan;

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

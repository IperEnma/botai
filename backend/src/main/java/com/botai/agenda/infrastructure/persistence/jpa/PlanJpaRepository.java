package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.PlanEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PlanJpaRepository extends JpaRepository<PlanEntity, UUID> {

    Optional<PlanEntity> findByIdAndDeletedAtIsNull(UUID id);

    List<PlanEntity> findAllByBusinessIdAndDeletedAtIsNull(UUID businessId);

    List<PlanEntity> findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(UUID businessId);

    @Modifying
    @Query("UPDATE PlanEntity p SET p.deletedAt = CURRENT_TIMESTAMP, p.activo = false WHERE p.id = :id")
    int softDelete(@Param("id") UUID id);
}

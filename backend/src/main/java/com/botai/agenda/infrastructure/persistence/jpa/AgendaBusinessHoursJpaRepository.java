package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.BusinessHoursEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AgendaBusinessHoursJpaRepository extends JpaRepository<BusinessHoursEntity, UUID> {

    List<BusinessHoursEntity> findByBusinessId(UUID businessId);

    void deleteByBusinessId(UUID businessId);
}

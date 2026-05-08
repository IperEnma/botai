package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.BusinessHoursEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AgendaBusinessHoursJpaRepository extends JpaRepository<BusinessHoursEntity, UUID> {

    List<BusinessHoursEntity> findByBusinessId(UUID businessId);

    void deleteByBusinessId(UUID businessId);
}

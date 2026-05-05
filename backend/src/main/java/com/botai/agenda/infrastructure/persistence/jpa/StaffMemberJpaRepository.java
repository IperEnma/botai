package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.infrastructure.persistence.entity.StaffMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StaffMemberJpaRepository extends JpaRepository<StaffMemberEntity, UUID> {

    List<StaffMemberEntity> findByBusinessId(UUID businessId);

    List<StaffMemberEntity> findByBusinessIdAndActivoTrueAndDeletedAtIsNull(UUID businessId);

    boolean existsByIdAndBusinessId(UUID id, UUID businessId);
}

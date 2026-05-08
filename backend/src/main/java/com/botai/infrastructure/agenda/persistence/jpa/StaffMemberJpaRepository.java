package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.StaffMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StaffMemberJpaRepository extends JpaRepository<StaffMemberEntity, UUID> {

    List<StaffMemberEntity> findByBusinessId(UUID businessId);

    List<StaffMemberEntity> findByBusinessIdAndActivoTrueAndDeletedAtIsNull(UUID businessId);

    boolean existsByIdAndBusinessId(UUID id, UUID businessId);
}

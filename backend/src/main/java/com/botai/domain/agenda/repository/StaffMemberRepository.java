package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.StaffMember;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface StaffMemberRepository {

    Optional<StaffMember> findById(UUID id);

    List<StaffMember> findByBusinessId(UUID businessId);

    List<StaffMember> findActiveByBusinessId(UUID businessId);

    StaffMember save(StaffMember staffMember);

    void softDelete(UUID id);

    boolean existsByIdAndBusinessId(UUID id, UUID businessId);
}

package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.StaffMember;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface StaffMemberRepository {

    Optional<StaffMember> findById(UUID id);

    /**
     * Resuelve el {@link StaffMember} vinculado a un {@code userId} en una
     * sucursal concreta. Devuelve vacío si el usuario no tiene perfil de
     * staff en esa sucursal (es decir, no es profesional ahí). Usado por el
     * gating RBAC para verificar que un STAFF solo actúe sobre sus propias
     * reservas.
     */
    Optional<StaffMember> findByUserIdAndBusinessId(UUID userId, UUID businessId);

    List<StaffMember> findByBusinessId(UUID businessId);

    List<StaffMember> findActiveByBusinessId(UUID businessId);

    StaffMember save(StaffMember staffMember);

    StaffMember updateServiceIds(UUID staffId, List<UUID> serviceIds);

    void softDelete(UUID id);

    boolean existsByIdAndBusinessId(UUID id, UUID businessId);
}

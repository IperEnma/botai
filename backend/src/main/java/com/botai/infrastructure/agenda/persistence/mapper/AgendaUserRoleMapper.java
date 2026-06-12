package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.infrastructure.agenda.persistence.entity.AgendaUserRoleEntity;

public final class AgendaUserRoleMapper {

    private AgendaUserRoleMapper() {}

    public static AgendaUserRole toDomain(AgendaUserRoleEntity e) {
        if (e == null) return null;
        return new AgendaUserRole(
                e.getId(),
                e.getUserId(),
                e.getTenantId(),
                e.getBusinessId(),
                e.getRole(),
                e.getCreatedAt(),
                e.getUpdatedAt()
        );
    }

    public static AgendaUserRoleEntity toEntity(AgendaUserRole r) {
        if (r == null) return null;
        AgendaUserRoleEntity e = new AgendaUserRoleEntity();
        e.setId(r.getId());
        e.setUserId(r.getUserId());
        e.setTenantId(r.getTenantId());
        e.setBusinessId(r.getBusinessId());
        e.setRole(r.getRole());
        // createdAt / updatedAt los gestiona BaseAuditableEntity vía AuditingEntityListener.
        return e;
    }
}

package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.StaffMember;
import com.botai.agenda.infrastructure.persistence.entity.StaffMemberEntity;

public final class StaffMemberMapper {

    private StaffMemberMapper() {
    }

    public static StaffMember toDomain(StaffMemberEntity e) {
        if (e == null) return null;
        return new StaffMember(
                e.getId(),
                e.getBusinessId(),
                e.getNombre(),
                e.getRol(),
                e.getAvatarUrl(),
                e.isActivo(),
                e.getDeletedAt(),
                e.getCreatedAt(),
                e.getUpdatedAt()
        );
    }

    public static StaffMemberEntity toEntity(StaffMember s) {
        if (s == null) return null;
        StaffMemberEntity e = new StaffMemberEntity();
        e.setId(s.getId());
        e.setBusinessId(s.getBusinessId());
        e.setNombre(s.getNombre());
        e.setRol(s.getRol());
        e.setAvatarUrl(s.getAvatarUrl());
        e.setActivo(s.isActivo());
        e.setDeletedAt(s.getDeletedAt());
        // createdAt / updatedAt los maneja @EntityListeners de BaseAuditableEntity.
        return e;
    }
}

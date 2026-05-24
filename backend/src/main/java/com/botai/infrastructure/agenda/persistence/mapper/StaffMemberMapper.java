package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.StaffMember;
import com.botai.infrastructure.agenda.persistence.entity.StaffMemberEntity;

import java.util.ArrayList;
import java.util.LinkedHashSet;

public final class StaffMemberMapper {

    private StaffMemberMapper() {
    }

    public static StaffMember toDomain(StaffMemberEntity e) {
        if (e == null) return null;
        return StaffMember.builder()
                .id(e.getId())
                .businessId(e.getBusinessId())
                .nombre(e.getNombre())
                .rol(e.getRol())
                .avatarUrl(e.getAvatarUrl())
                .telefono(e.getTelefono())
                .email(e.getEmail())
                .bio(e.getBio())
                .color(e.getColor())
                .status(e.getStatus() != null ? e.getStatus() : (e.isActivo() ? "ACTIVO" : "ARCHIVADO"))
                .customSchedule(e.getCustomSchedule())
                .serviceIds(e.getServiceIds() != null ? new ArrayList<>(e.getServiceIds()) : new ArrayList<>())
                .deletedAt(e.getDeletedAt())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }

    public static StaffMemberEntity toEntity(StaffMember s) {
        if (s == null) return null;
        StaffMemberEntity e = new StaffMemberEntity();
        e.setId(s.getId());
        e.setBusinessId(s.getBusinessId());
        e.setNombre(s.getNombre());
        e.setRol(s.getRol());
        e.setAvatarUrl(s.getAvatarUrl());
        e.setTelefono(s.getTelefono());
        e.setEmail(s.getEmail());
        e.setBio(s.getBio());
        e.setColor(s.getColor());
        e.setStatus(s.getStatus() != null ? s.getStatus() : "ACTIVO");
        e.setActivo(s.isActivo()); // backward compat: mantener activo sincronizado con status
        e.setCustomSchedule(s.getCustomSchedule());
        e.setDeletedAt(s.getDeletedAt());
        e.setServiceIds(s.getServiceIds() != null ? new LinkedHashSet<>(s.getServiceIds()) : new LinkedHashSet<>());
        // createdAt / updatedAt los maneja @EntityListeners de BaseAuditableEntity.
        return e;
    }
}

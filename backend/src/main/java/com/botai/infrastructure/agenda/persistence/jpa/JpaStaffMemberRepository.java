package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.botai.infrastructure.agenda.persistence.mapper.StaffMemberMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaStaffMemberRepository implements StaffMemberRepository {

    private final StaffMemberJpaRepository jpaRepository;

    public JpaStaffMemberRepository(StaffMemberJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Optional<StaffMember> findById(UUID id) {
        return jpaRepository.findById(id).map(StaffMemberMapper::toDomain);
    }

    @Override
    public Optional<StaffMember> findByUserIdAndBusinessId(UUID userId, UUID businessId) {
        if (userId == null || businessId == null) return Optional.empty();
        return jpaRepository.findByUserIdAndBusinessId(userId, businessId)
                .map(StaffMemberMapper::toDomain);
    }

    @Override
    public List<StaffMember> findByBusinessId(UUID businessId) {
        return jpaRepository.findByBusinessId(businessId)
                .stream()
                .map(StaffMemberMapper::toDomain)
                .toList();
    }

    @Override
    public List<StaffMember> findActiveByBusinessId(UUID businessId) {
        return jpaRepository.findActiveByBusinessId(businessId)
                .stream()
                .map(StaffMemberMapper::toDomain)
                .toList();
    }

    @Override
    public StaffMember save(StaffMember staffMember) {
        if (staffMember.getId() != null) {
            // Para updates: cargar entidad existente y preservar las colecciones
            // (serviceIds + businessIds) gestionadas por endpoints específicos.
            return jpaRepository.findById(staffMember.getId())
                    .map(existing -> {
                        existing.setUserId(staffMember.getUserId());
                        existing.setNombre(staffMember.getNombre());
                        existing.setRol(staffMember.getRol());
                        existing.setAvatarUrl(staffMember.getAvatarUrl());
                        existing.setTelefono(staffMember.getTelefono());
                        existing.setEmail(staffMember.getEmail());
                        existing.setBio(staffMember.getBio());
                        existing.setColor(staffMember.getColor());
                        String newStatus = staffMember.getStatus() != null ? staffMember.getStatus() : "ACTIVO";
                        existing.setStatus(newStatus);
                        existing.setActivo(staffMember.isActivo()); // mantener en sync con status
                        existing.setCustomSchedule(staffMember.getCustomSchedule());
                        existing.setDeletedAt(staffMember.getDeletedAt());
                        // Si el dominio trae businessIds no vacío, reemplaza; si vacío,
                        // preserva (caso típico: update parcial de datos).
                        if (staffMember.getBusinessIds() != null && !staffMember.getBusinessIds().isEmpty()) {
                            existing.getBusinessIds().clear();
                            existing.getBusinessIds().addAll(staffMember.getBusinessIds());
                        }
                        return StaffMemberMapper.toDomain(jpaRepository.save(existing));
                    })
                    .orElseGet(() -> {
                        var entity = StaffMemberMapper.toEntity(staffMember);
                        return StaffMemberMapper.toDomain(jpaRepository.save(entity));
                    });
        }
        var entity = StaffMemberMapper.toEntity(staffMember);
        var saved = jpaRepository.save(entity);
        return StaffMemberMapper.toDomain(saved);
    }

    @Override
    public StaffMember updateServiceIds(UUID staffId, List<UUID> serviceIds) {
        var entity = jpaRepository.findById(staffId)
                .orElseThrow(() -> new IllegalArgumentException("StaffMember not found: " + staffId));
        entity.getServiceIds().clear();
        if (serviceIds != null) {
            entity.getServiceIds().addAll(serviceIds);
        }
        return StaffMemberMapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public void softDelete(UUID id) {
        jpaRepository.findById(id).ifPresent(entity -> {
            entity.setDeletedAt(LocalDateTime.now());
            entity.setActivo(false);
            entity.setStatus("PAUSADO");
            jpaRepository.save(entity);
        });
    }

    @Override
    public boolean existsByIdAndBusinessId(UUID id, UUID businessId) {
        return jpaRepository.existsByIdAndBusinessId(id, businessId);
    }
}

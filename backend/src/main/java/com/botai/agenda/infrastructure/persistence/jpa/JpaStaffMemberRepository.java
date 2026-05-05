package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.StaffMember;
import com.botai.agenda.domain.repository.StaffMemberRepository;
import com.botai.agenda.infrastructure.persistence.mapper.StaffMemberMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
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
    public List<StaffMember> findByBusinessId(UUID businessId) {
        return jpaRepository.findByBusinessId(businessId)
                .stream()
                .map(StaffMemberMapper::toDomain)
                .toList();
    }

    @Override
    public List<StaffMember> findActiveByBusinessId(UUID businessId) {
        return jpaRepository.findByBusinessIdAndActivoTrueAndDeletedAtIsNull(businessId)
                .stream()
                .map(StaffMemberMapper::toDomain)
                .toList();
    }

    @Override
    public StaffMember save(StaffMember staffMember) {
        var entity = StaffMemberMapper.toEntity(staffMember);
        var saved = jpaRepository.save(entity);
        return StaffMemberMapper.toDomain(saved);
    }

    @Override
    public void softDelete(UUID id) {
        jpaRepository.findById(id).ifPresent(entity -> {
            entity.setDeletedAt(LocalDateTime.now());
            entity.setActivo(false);
            jpaRepository.save(entity);
        });
    }

    @Override
    public boolean existsByIdAndBusinessId(UUID id, UUID businessId) {
        return jpaRepository.existsByIdAndBusinessId(id, businessId);
    }
}

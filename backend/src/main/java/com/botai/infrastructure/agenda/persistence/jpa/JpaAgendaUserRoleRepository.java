package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.infrastructure.agenda.persistence.mapper.AgendaUserRoleMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaAgendaUserRoleRepository implements AgendaUserRoleRepository {

    private final AgendaUserRoleJpaRepository jpa;

    public JpaAgendaUserRoleRepository(AgendaUserRoleJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public AgendaUserRole save(AgendaUserRole assignment) {
        return AgendaUserRoleMapper.toDomain(
                jpa.save(AgendaUserRoleMapper.toEntity(assignment)));
    }

    @Override
    public Optional<AgendaUserRole> findById(UUID id) {
        return jpa.findById(id).map(AgendaUserRoleMapper::toDomain);
    }

    @Override
    public List<AgendaUserRole> findByUserId(UUID userId) {
        return jpa.findByUserId(userId).stream()
                .map(AgendaUserRoleMapper::toDomain)
                .toList();
    }

    @Override
    public List<AgendaUserRole> findByUserIdAndTenantId(UUID userId, String tenantId) {
        return jpa.findByUserIdAndTenantId(userId, tenantId).stream()
                .map(AgendaUserRoleMapper::toDomain)
                .toList();
    }

    @Override
    public List<AgendaUserRole> findByTenantId(String tenantId) {
        return jpa.findByTenantId(tenantId).stream()
                .map(AgendaUserRoleMapper::toDomain)
                .toList();
    }

    @Override
    public boolean isPlatformAdmin(UUID userId) {
        return jpa.existsByUserIdAndRole(userId, Role.PLATFORM_ADMIN);
    }

    @Override
    public boolean existsOwnerByTenantId(String tenantId) {
        return jpa.existsByTenantIdAndRole(tenantId, Role.OWNER);
    }

    @Override
    public Optional<AgendaUserRole> findOwnerByTenantId(String tenantId) {
        return jpa.findFirstByTenantIdAndRole(tenantId, Role.OWNER)
                .map(AgendaUserRoleMapper::toDomain);
    }

    @Override
    public boolean exists(UUID userId, String tenantId, UUID businessId, Role role) {
        if (tenantId == null) {
            return jpa.existsByUserIdAndTenantIdIsNullAndBusinessIdIsNullAndRole(userId, role);
        }
        if (businessId == null) {
            return jpa.existsByUserIdAndTenantIdAndBusinessIdIsNullAndRole(userId, tenantId, role);
        }
        return jpa.existsByUserIdAndTenantIdAndBusinessIdAndRole(userId, tenantId, businessId, role);
    }

    @Override
    public void delete(UUID id) {
        jpa.deleteById(id);
    }
}

package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.Role;
import com.botai.infrastructure.agenda.persistence.entity.AgendaUserRoleEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AgendaUserRoleJpaRepository extends JpaRepository<AgendaUserRoleEntity, UUID> {

    List<AgendaUserRoleEntity> findByUserId(UUID userId);

    List<AgendaUserRoleEntity> findByUserIdAndTenantId(UUID userId, String tenantId);

    List<AgendaUserRoleEntity> findByTenantId(String tenantId);

    boolean existsByUserIdAndRole(UUID userId, Role role);

    boolean existsByTenantIdAndRole(String tenantId, Role role);

    Optional<AgendaUserRoleEntity> findFirstByTenantIdAndRole(String tenantId, Role role);

    boolean existsByUserIdAndTenantIdAndBusinessIdAndRole(
            UUID userId, String tenantId, UUID businessId, Role role);

    boolean existsByUserIdAndTenantIdAndBusinessIdIsNullAndRole(
            UUID userId, String tenantId, Role role);

    boolean existsByUserIdAndTenantIdIsNullAndBusinessIdIsNullAndRole(
            UUID userId, Role role);
}

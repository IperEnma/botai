package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port para la persistencia de asignaciones de rol.
 *
 * <p>Las consultas están moldeadas para los casos de uso de la capa de
 * autorización (Fase 2): cargar todos los roles efectivos de un usuario para
 * un tenant, verificar si un tenant ya tiene OWNER, etc.</p>
 */
public interface AgendaUserRoleRepository {

    AgendaUserRole save(AgendaUserRole assignment);

    Optional<AgendaUserRole> findById(UUID id);

    /** Todos los roles del usuario (cualquier tenant, incluye PLATFORM_ADMIN). */
    List<AgendaUserRole> findByUserId(UUID userId);

    /** Roles efectivos del usuario dentro de un tenant. */
    List<AgendaUserRole> findByUserIdAndTenantId(UUID userId, String tenantId);

    /** Todos los actores con rol en un tenant. */
    List<AgendaUserRole> findByTenantId(String tenantId);

    boolean isPlatformAdmin(UUID userId);

    /** Existe ya un OWNER activo para el tenant. */
    boolean existsOwnerByTenantId(String tenantId);

    Optional<AgendaUserRole> findOwnerByTenantId(String tenantId);

    /** Verifica si el usuario ya tiene un rol concreto en un scope dado. */
    boolean exists(UUID userId, String tenantId, UUID businessId, Role role);

    void delete(UUID id);
}

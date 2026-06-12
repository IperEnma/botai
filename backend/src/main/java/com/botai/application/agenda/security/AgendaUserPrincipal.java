package com.botai.application.agenda.security;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Identidad efectiva de un usuario autenticado: quién es y qué roles tiene
 * resueltos en cada scope (plataforma / tenant / sucursal).
 *
 * <p>Inmutable. Producido por {@link AgendaPrincipalLoader} a partir de la
 * resolución JWT-email → tenant → user → roles.</p>
 */
public final class AgendaUserPrincipal {

    private final UUID userId;
    private final String email;
    private final String tenantId;
    private final List<AgendaUserRole> roles;
    private final boolean platformAdmin;
    private final boolean owner;
    private final boolean tenantAdmin;

    public AgendaUserPrincipal(UUID userId,
                                String email,
                                String tenantId,
                                List<AgendaUserRole> roles) {
        this.userId = userId;
        this.email = email;
        this.tenantId = tenantId;
        this.roles = roles != null ? List.copyOf(roles) : List.of();
        this.platformAdmin = this.roles.stream().anyMatch(r -> r.getRole() == Role.PLATFORM_ADMIN);
        this.owner         = this.roles.stream().anyMatch(r ->
                r.getRole() == Role.OWNER && tenantId != null && tenantId.equals(r.getTenantId()));
        this.tenantAdmin   = this.roles.stream().anyMatch(r ->
                r.getRole() == Role.TENANT_ADMIN && tenantId != null && tenantId.equals(r.getTenantId()));
    }

    /** Anónimo: ningún claim válido. Todas las verificaciones devuelven false. */
    public static AgendaUserPrincipal anonymous() {
        return new AgendaUserPrincipal(null, null, null, List.of());
    }

    public UUID getUserId()            { return userId; }
    public String getEmail()           { return email; }
    public String getTenantId()        { return tenantId; }
    public List<AgendaUserRole> getRoles() { return roles; }

    public boolean isAuthenticated()   { return userId != null; }
    public boolean isPlatformAdmin()   { return platformAdmin; }
    public boolean isOwner()           { return owner; }
    public boolean isTenantAdmin()     { return tenantAdmin; }
    public boolean isAdministrative()  { return owner || tenantAdmin; }

    /**
     * Tiene el rol concreto a nivel tenant ({@code business_id == null}) dentro
     * del tenant actual.
     */
    public boolean hasTenantRole(Role role) {
        if (tenantId == null) return false;
        return roles.stream().anyMatch(r ->
                r.getRole() == role
                        && r.getBusinessId() == null
                        && tenantId.equals(r.getTenantId()));
    }

    /** Tiene el rol concreto sobre la sucursal dada. */
    public boolean hasBusinessRole(Role role, UUID businessId) {
        if (businessId == null) return false;
        return roles.stream().anyMatch(r ->
                r.getRole() == role && businessId.equals(r.getBusinessId()));
    }

    /** Tiene alguno de los roles candidatos sobre la sucursal. */
    public boolean hasAnyBusinessRole(UUID businessId, Role... candidates) {
        if (businessId == null || candidates == null) return false;
        for (Role role : candidates) {
            if (hasBusinessRole(role, businessId)) return true;
        }
        return false;
    }

    /** Sucursales asignadas para un rol concreto (RECEPTION / STAFF_*). */
    public Set<UUID> businessesFor(Role role) {
        return roles.stream()
                .filter(r -> r.getRole() == role && r.getBusinessId() != null)
                .map(AgendaUserRole::getBusinessId)
                .collect(Collectors.toUnmodifiableSet());
    }
}

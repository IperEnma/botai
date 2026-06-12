package com.botai.domain.agenda.model;

/**
 * Roles de autorización del módulo AGENDA.
 *
 * <p>Cada asignación de rol vive en {@link AgendaUserRole}; el rol define qué
 * scope (plataforma, tenant o sucursal) es válido para esa asignación.</p>
 *
 * <p>Fuente: {@code backend/docs/AGENDA_RBAC_ENDPOINTS.md}.</p>
 */
public enum Role {

    PLATFORM_ADMIN,
    OWNER,
    TENANT_ADMIN,
    RECEPTION,
    STAFF_VIEWER,
    STAFF_OPERATOR,
    CLIENT;

    /** Roles cuyo scope es la plataforma global (sin tenant). */
    public boolean isPlatformScope() {
        return this == PLATFORM_ADMIN;
    }

    /** Roles cuyo scope es el tenant completo (sin business). */
    public boolean isTenantScope() {
        return this == OWNER || this == TENANT_ADMIN || this == CLIENT;
    }

    /** Roles que requieren una sucursal asignada. */
    public boolean isBusinessScope() {
        return this == RECEPTION || this == STAFF_VIEWER || this == STAFF_OPERATOR;
    }

    /** Roles administrativos sobre un tenant (mutación de configuración). */
    public boolean isTenantAdministrative() {
        return this == OWNER || this == TENANT_ADMIN;
    }

    /** Roles operativos de staff (interactúan con su propia agenda). */
    public boolean isStaff() {
        return this == STAFF_VIEWER || this == STAFF_OPERATOR;
    }
}

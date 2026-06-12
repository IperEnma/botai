package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Asignación de un rol a un usuario dentro de un scope determinado.
 *
 * <ul>
 *   <li>{@link Role#PLATFORM_ADMIN} → {@code tenantId == null}, {@code businessId == null}.</li>
 *   <li>{@link Role#OWNER}, {@link Role#TENANT_ADMIN}, {@link Role#CLIENT}
 *       → {@code tenantId != null}, {@code businessId == null}.</li>
 *   <li>{@link Role#RECEPTION}, {@link Role#STAFF_VIEWER}, {@link Role#STAFF_OPERATOR}
 *       → {@code tenantId != null}, {@code businessId != null}.</li>
 * </ul>
 *
 * Las invariantes de scope se validan en el constructor y, en la base, mediante
 * el CHECK {@code chk_agenda_user_roles_scope} en {@code V3}.
 */
public final class AgendaUserRole {

    private final UUID id;
    private final UUID userId;
    private final String tenantId;
    private final UUID businessId;
    private final Role role;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public AgendaUserRole(UUID id,
                          UUID userId,
                          String tenantId,
                          UUID businessId,
                          Role role,
                          LocalDateTime createdAt,
                          LocalDateTime updatedAt) {
        this.userId = Objects.requireNonNull(userId, "userId");
        this.role = Objects.requireNonNull(role, "role");
        validateScope(role, tenantId, businessId);
        this.id = id;
        this.tenantId = tenantId;
        this.businessId = businessId;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static AgendaUserRole platform(UUID userId) {
        return new AgendaUserRole(null, userId, null, null, Role.PLATFORM_ADMIN, null, null);
    }

    public static AgendaUserRole tenantWide(UUID userId, String tenantId, Role role) {
        if (!role.isTenantScope()) {
            throw new IllegalArgumentException("Rol no es de scope tenant: " + role);
        }
        return new AgendaUserRole(null, userId, tenantId, null, role, null, null);
    }

    public static AgendaUserRole forBusiness(UUID userId, String tenantId, UUID businessId, Role role) {
        if (!role.isBusinessScope()) {
            throw new IllegalArgumentException("Rol no es de scope business: " + role);
        }
        return new AgendaUserRole(null, userId, tenantId, businessId, role, null, null);
    }

    private static void validateScope(Role role, String tenantId, UUID businessId) {
        if (role.isPlatformScope()) {
            if (tenantId != null || businessId != null) {
                throw new IllegalArgumentException(
                        "PLATFORM_ADMIN no puede llevar tenantId ni businessId");
            }
            return;
        }
        if (tenantId == null || tenantId.isBlank()) {
            throw new IllegalArgumentException("tenantId requerido para rol " + role);
        }
        if (role.isTenantScope() && businessId != null) {
            throw new IllegalArgumentException(
                    "Rol " + role + " es tenant-wide; businessId debe ser null");
        }
        if (role.isBusinessScope() && businessId == null) {
            throw new IllegalArgumentException("businessId requerido para rol " + role);
        }
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getTenantId() { return tenantId; }
    public UUID getBusinessId() { return businessId; }
    public Role getRole() { return role; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

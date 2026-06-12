package com.botai.infrastructure.agenda.persistence.entity;

import com.botai.domain.agenda.model.Role;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.Checks;

import java.util.UUID;

/**
 * Tabla {@code agenda_user_roles}. Cada fila es una asignación de rol.
 *
 * <p>Invariantes de scope ({@code chk_agenda_user_roles_scope}):</p>
 * <ul>
 *   <li>{@code PLATFORM_ADMIN}                       → tenant_id NULL ∧ business_id NULL</li>
 *   <li>{@code OWNER}, {@code TENANT_ADMIN}, {@code CLIENT} → tenant_id NOT NULL ∧ business_id NULL</li>
 *   <li>{@code RECEPTION}, {@code STAFF_VIEWER}, {@code STAFF_OPERATOR} → tenant_id NOT NULL ∧ business_id NOT NULL</li>
 * </ul>
 *
 * <p>Unicidad por usuario+scope: índice parcial {@code uk_agenda_user_roles_unique} en V4.</p>
 */
@Entity(name = "AgendaUserRoleEntity")
@Table(
        name = "agenda_user_roles",
        indexes = {
                @Index(name = "idx_agenda_user_roles_user", columnList = "user_id"),
                @Index(name = "idx_agenda_user_roles_tenant", columnList = "tenant_id"),
                @Index(name = "idx_agenda_user_roles_user_tenant", columnList = "user_id, tenant_id")
        }
)
@Checks({
        @Check(name = "chk_agenda_user_roles_scope", constraints =
                "(role = 'PLATFORM_ADMIN' AND tenant_id IS NULL AND business_id IS NULL)"
                + " OR (role IN ('OWNER','TENANT_ADMIN','CLIENT')"
                + "     AND tenant_id IS NOT NULL AND business_id IS NULL)"
                + " OR (role IN ('RECEPTION','STAFF_VIEWER','STAFF_OPERATOR')"
                + "     AND tenant_id IS NOT NULL AND business_id IS NOT NULL)")
})
public class AgendaUserRoleEntity extends BaseAuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "tenant_id", length = 64)
    private String tenantId;

    @Column(name = "business_id")
    private UUID businessId;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 32)
    private Role role;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }

    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
}

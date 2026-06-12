package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.CreateTenantInvitationRequest;
import com.botai.application.agenda.dto.ReassignTenantUserRolesRequest;
import com.botai.application.agenda.dto.TenantInvitationResponse;
import com.botai.application.agenda.usecase.rbac.InviteTenantUserUseCase;
import com.botai.application.agenda.usecase.rbac.ReassignTenantUserRolesUseCase;
import com.botai.application.agenda.usecase.rbac.RevokeTenantUserUseCase;
import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Gestión de usuarios del tenant: invitaciones, reasignación de roles, revocación.
 *
 * <p>El control fino de "quién puede invitar a qué rol" está en
 * {@code @authz.canInviteRole}: OWNER puede invitar {@code TENANT_ADMIN};
 * OWNER y TENANT_ADMIN pueden invitar {@code STAFF_*}/{@code RECEPTION}.
 * Reasignar y revocar son OWNER only.</p>
 */
@RestController
@RequestMapping("/api/agenda/me/tenant")
@Tag(name = "Agenda Me · Tenant Users", description = "Invitaciones y gestión de miembros del tenant")
@Validated
public class MeTenantUsersController {

    private final InviteTenantUserUseCase inviteUser;
    private final ReassignTenantUserRolesUseCase reassignRoles;
    private final RevokeTenantUserUseCase revokeUser;
    private final AgendaCurrentTenantService currentTenant;

    public MeTenantUsersController(InviteTenantUserUseCase inviteUser,
                                   ReassignTenantUserRolesUseCase reassignRoles,
                                   RevokeTenantUserUseCase revokeUser,
                                   AgendaCurrentTenantService currentTenant) {
        this.inviteUser = inviteUser;
        this.reassignRoles = reassignRoles;
        this.revokeUser = revokeUser;
        this.currentTenant = currentTenant;
    }

    @PostMapping("/invitations")
    @Operation(
            summary = "Invita un usuario al tenant con un rol RBAC",
            description = "Crea (o reusa) el User, asigna el rol pedido y, "
                    + "para roles STAFF_*, crea el StaffMember linkeado en cada sucursal."
    )
    @PreAuthorize("@authz.canInviteRole(#request.role())")
    public ResponseEntity<TenantInvitationResponse> invite(
            @Valid @RequestBody CreateTenantInvitationRequest request) {
        String tenantId = currentTenant.requireTenantId();
        TenantInvitationResponse response = inviteUser.execute(tenantId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PatchMapping("/users/{userId}/roles")
    @Operation(
            summary = "Reasigna por completo los roles de un usuario en este tenant",
            description = "Reemplaza todas las asignaciones del usuario. No puede tocar OWNER."
    )
    @PreAuthorize("@authz.isOwner()")
    public ResponseEntity<List<Map<String, Object>>> reassignRoles(
            @PathVariable("userId") UUID userId,
            @Valid @RequestBody ReassignTenantUserRolesRequest request) {
        String tenantId = currentTenant.requireTenantId();
        List<AgendaUserRole> updated = reassignRoles.execute(tenantId, userId, request);
        List<Map<String, Object>> body = updated.stream()
                .map(r -> {
                    Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("role", r.getRole().name());
                    m.put("businessId", r.getBusinessId());
                    return m;
                })
                .toList();
        return ResponseEntity.ok(body);
    }

    @DeleteMapping("/users/{userId}")
    @Operation(
            summary = "Revoca todo acceso del usuario al tenant",
            description = "Borra sus roles, desvincula su StaffMember si lo tenía. No borra el User ni el StaffMember."
    )
    @PreAuthorize("@authz.isOwner()")
    public ResponseEntity<Void> revoke(@PathVariable("userId") UUID userId) {
        String tenantId = currentTenant.requireTenantId();
        revokeUser.execute(tenantId, userId);
        return ResponseEntity.noContent().build();
    }
}

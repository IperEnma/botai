package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.MeProfileResponse;
import com.botai.application.agenda.security.AgendaUserPrincipal;
import com.botai.application.agenda.usecase.rbac.AgendaRoleBootstrapService;
import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.infrastructure.agenda.security.AgendaUserContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Identidad y roles efectivos del usuario autenticado — base del RBAC client-side.
 *
 * <p>El frontend lo invoca una vez al cargar la app (tras Google sign-in) y
 * cachea la respuesta. Cualquier UI condicional (botones, pantallas, items de
 * navegación) consume este perfil sin volver a consultar al backend.</p>
 *
 * <p>Side-effect: dispara {@link AgendaRoleBootstrapService#ensureOwnerByJwtEmail}
 * para tenants pre-RBAC. Eso garantiza que un OWNER legítimo nunca quede sin
 * permisos por la sola migración.</p>
 */
@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Profile", description = "Identidad y roles efectivos del usuario autenticado")
public class MeProfileController {

    private final AgendaUserContext userContext;
    private final AgendaRoleBootstrapService roleBootstrap;

    public MeProfileController(AgendaUserContext userContext,
                               AgendaRoleBootstrapService roleBootstrap) {
        this.userContext = userContext;
        this.roleBootstrap = roleBootstrap;
    }

    @GetMapping("/profile")
    @Operation(summary = "Perfil RBAC del usuario autenticado (userId, tenant, roles efectivos)")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MeProfileResponse> profile(@AuthenticationPrincipal Jwt jwt) {
        AgendaUserPrincipal principal = userContext.principal();
        final String jwtEmail = jwt != null ? jwt.getClaimAsString("email") : null;

        // Auto-bootstrap PLATFORM_ADMIN: si el email del JWT matchea el
        // configurado en `platform.admin-email` y el usuario aún no tiene PA,
        // se le asigna acá. Idempotente y cero-ceremonia.
        boolean platformBootstrapped = roleBootstrap
                .ensurePlatformAdminByEmail(jwtEmail).isPresent()
                && !principal.isPlatformAdmin();

        // Auto-bootstrap OWNER: si el tenant existía antes de RBAC y aún no
        // tiene OWNER, el primer hit a /me/profile lo asigna al usuario del
        // JWT (si su email matchea el TenantAccount).
        final String currentTenantId = principal.getTenantId();
        boolean lacksAdminRole = currentTenantId != null
                && principal.getRoles().stream().noneMatch(r ->
                        r.getRole().isTenantAdministrative()
                                && currentTenantId.equals(r.getTenantId()));
        boolean ownerBootstrapped = false;
        if (lacksAdminRole) {
            roleBootstrap.ensureOwnerByJwtEmail(jwtEmail, currentTenantId);
            ownerBootstrapped = true;
        }
        if (platformBootstrapped || ownerBootstrapped) {
            // Invalidar la cache del request: bootstrap acaba de mutar las
            // asignaciones de rol del usuario actual.
            principal = userContext.reload();
        }

        List<MeProfileResponse.RoleAssignmentDto> roleDtos = principal.getRoles().stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(new MeProfileResponse(
                principal.getUserId(),
                principal.getEmail(),
                principal.getTenantId(),
                roleDtos,
                principal.isPlatformAdmin(),
                principal.isOwner(),
                principal.isTenantAdmin()
        ));
    }

    private MeProfileResponse.RoleAssignmentDto toDto(AgendaUserRole r) {
        return new MeProfileResponse.RoleAssignmentDto(r.getRole().name(), r.getBusinessId());
    }
}

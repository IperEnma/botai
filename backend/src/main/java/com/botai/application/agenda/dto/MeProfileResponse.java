package com.botai.application.agenda.dto;

import java.util.List;
import java.util.UUID;

/**
 * Perfil efectivo del usuario autenticado: identidad + roles RBAC + booleanos
 * pre-calculados para que el frontend pueda gatear UI sin re-implementar la
 * lógica de scope.
 *
 * <p>Endpoint: {@code GET /api/agenda/me/profile}.</p>
 *
 * <p><b>Convenciones:</b></p>
 * <ul>
 *   <li>{@code userId == null}: el JWT no resolvió a un {@code User} dentro de
 *       un tenant. Frontend debe tratar como "perfil incompleto".</li>
 *   <li>{@code tenantId == null}: solo en {@code PLATFORM_ADMIN} sin tenant
 *       propio, o usuario sin tenant resuelto.</li>
 *   <li>{@code roles}: cada elemento lleva el rol y el {@code businessId}
 *       ({@code null} para roles tenant-wide o platform-wide).</li>
 *   <li>{@code platformAdmin / owner / tenantAdmin}: pre-calculados para
 *       chequeos rápidos en el frontend sin recorrer {@code roles}.</li>
 * </ul>
 */
public record MeProfileResponse(
        UUID userId,
        String email,
        String tenantId,
        List<RoleAssignmentDto> roles,
        boolean platformAdmin,
        boolean owner,
        boolean tenantAdmin
) {
    public record RoleAssignmentDto(
            String role,
            UUID businessId
    ) {}
}

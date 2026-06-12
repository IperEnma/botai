package com.botai.application.agenda.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;

import java.util.List;
import java.util.UUID;

/**
 * Reemplaza por completo las asignaciones de rol de un {@code User} dentro
 * del tenant actual.
 *
 * <p>Sólo OWNER puede invocar este endpoint (ver {@code @authz}).</p>
 *
 * <p>Cada {@link AssignmentSpec} indica un rol + las sucursales donde aplica.
 * Para {@code TENANT_ADMIN} se ignora {@code businessIds}; para los demás,
 * cada sucursal debe pertenecer al tenant actual.</p>
 */
public record ReassignTenantUserRolesRequest(
        @NotEmpty
        @Valid
        List<AssignmentSpec> assignments
) {

    public record AssignmentSpec(
            @NotBlank
            @Pattern(
                    regexp = "STAFF_OPERATOR|STAFF_VIEWER|RECEPTION|TENANT_ADMIN",
                    message = "role debe ser STAFF_OPERATOR, STAFF_VIEWER, RECEPTION o TENANT_ADMIN")
            String role,
            List<UUID> businessIds
    ) {}
}

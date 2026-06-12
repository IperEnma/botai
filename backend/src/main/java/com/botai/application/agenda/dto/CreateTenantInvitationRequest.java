package com.botai.application.agenda.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/**
 * Alta de un usuario miembro del tenant con un rol RBAC asignado.
 *
 * <ul>
 *   <li>{@code role}: uno de {@code STAFF_OPERATOR}, {@code STAFF_VIEWER},
 *       {@code RECEPTION} o {@code TENANT_ADMIN}. El backend impide otros
 *       valores en el use case.</li>
 *   <li>{@code businessIds}: requerido para roles de scope business
 *       ({@code STAFF_*}, {@code RECEPTION}). Para {@code TENANT_ADMIN} se
 *       ignora — el rol es tenant-wide.</li>
 *   <li>Para roles {@code STAFF_*} se crea además un {@code StaffMember}
 *       linkeado al nuevo {@code User} en cada sucursal.</li>
 * </ul>
 */
public record CreateTenantInvitationRequest(
        @NotBlank
        @Size(max = 100)
        @Pattern(
                regexp = "^[a-zA-ZáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙüÜñÑ\\s']+$",
                message = "nombre solo puede contener letras y espacios")
        String nombre,

        @NotBlank
        @Email
        @Size(max = 200)
        String email,

        @Size(max = 50)
        @Pattern(
                regexp = "^\\+?[0-9]{6,}$",
                message = "telefono solo puede contener números (mínimo 6 dígitos)")
        String telefono,

        @NotBlank
        @Pattern(
                regexp = "STAFF_OPERATOR|STAFF_VIEWER|RECEPTION|TENANT_ADMIN",
                message = "role debe ser STAFF_OPERATOR, STAFF_VIEWER, RECEPTION o TENANT_ADMIN")
        String role,

        List<UUID> businessIds
) {

    @AssertTrue(message = "businessIds debe contener al menos una sucursal para STAFF_OPERATOR/STAFF_VIEWER/RECEPTION; debe estar vacío para TENANT_ADMIN")
    public boolean isBusinessIdsCoherentWithRole() {
        boolean isBusinessScoped = !"TENANT_ADMIN".equals(role);
        boolean hasBusinesses = businessIds != null && !businessIds.isEmpty();
        return isBusinessScoped == hasBusinesses;
    }
}

package com.botai.application.agenda.dto;

import java.util.List;
import java.util.UUID;

/**
 * Resultado del alta de un miembro del tenant via invitación.
 *
 * <ul>
 *   <li>{@code userExisted}: {@code true} si el {@code User} ya existía (alta
 *       previa como cliente final o miembro de otro rol) — solo se agregaron
 *       roles. {@code false} si se creó desde cero.</li>
 *   <li>{@code staffMemberId}: presente solo para roles {@code STAFF_*}.</li>
 * </ul>
 */
public record TenantInvitationResponse(
        UUID userId,
        String email,
        String nombre,
        String role,
        List<UUID> businessIds,
        UUID staffMemberId,
        boolean userExisted
) {
}

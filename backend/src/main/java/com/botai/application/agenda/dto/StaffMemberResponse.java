package com.botai.application.agenda.dto;

import com.fasterxml.jackson.annotation.JsonRawValue;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Respuesta pública/admin de un miembro del equipo.
 *
 * <p><b>Multi-sucursal:</b> {@link #businessIds} es la fuente de verdad.
 * {@link #businessId} se mantiene poblado con el primer elemento del set por
 * compatibilidad con clientes anteriores; se eliminará tras Fase 5.</p>
 */
public record StaffMemberResponse(
        UUID id,
        /**
         * userId del {@code User} vinculado a este staff (null cuando es
         * "STAFF sin cuenta"). El frontend lo usa para detectar cuál es el
         * staff member del usuario logueado.
         */
        UUID userId,
        UUID businessId,
        List<UUID> businessIds,
        String nombre,
        String rol,
        String avatarUrl,
        String telefono,
        String email,
        String bio,
        String color,
        boolean activo,
        String status,
        @JsonRawValue String customSchedule,
        List<UUID> serviceIds,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        Double rating,
        int reviewCount
) {
}

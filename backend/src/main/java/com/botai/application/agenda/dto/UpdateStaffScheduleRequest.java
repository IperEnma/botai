package com.botai.application.agenda.dto;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotNull;

/**
 * Update parcial del horario semanal de un staff member. Body de
 * {@code PATCH /me/businesses/{businessId}/staff/{staffId}/schedule}.
 *
 * <p>El backend clampa cada día dentro del horario del negocio
 * (mismo {@code sanitizeSchedule} que usa el PUT completo de staff).</p>
 */
public record UpdateStaffScheduleRequest(
        @NotNull JsonNode customSchedule
) {
}

package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record PlanResponse(
        UUID id,
        UUID businessId,
        String nombrePlan,
        PlanTipo tipo,
        PlanTier tier,
        Integer totalCreditos,
        int validezDias,
        BigDecimal precio,
        boolean activo,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}

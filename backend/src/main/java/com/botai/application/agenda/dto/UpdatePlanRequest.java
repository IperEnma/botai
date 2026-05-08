package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

/**
 * PATCH semántico: cualquier campo {@code null} significa "no cambiar".
 */
public record UpdatePlanRequest(
        String nombrePlan,
        PlanTipo tipo,
        PlanTier tier,
        @PositiveOrZero Integer totalCreditos,
        @Min(1) Integer validezDias,
        @DecimalMin("0.00") BigDecimal precio,
        Boolean activo
) {
}

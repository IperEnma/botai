package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CreatePlanRequest(
        @NotBlank String nombrePlan,
        @NotNull PlanTipo tipo,
        PlanTier tier,
        @PositiveOrZero Integer totalCreditos,
        @Min(1) int validezDias,
        @NotNull @DecimalMin("0.00") BigDecimal precio,
        Boolean activo
) {
}

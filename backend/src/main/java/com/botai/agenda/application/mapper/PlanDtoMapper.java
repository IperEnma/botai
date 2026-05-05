package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.PlanResponse;
import com.botai.agenda.domain.model.Plan;

public final class PlanDtoMapper {

    private PlanDtoMapper() {
    }

    public static PlanResponse toResponse(Plan plan) {
        if (plan == null) {
            return null;
        }
        return new PlanResponse(
                plan.getId(),
                plan.getBusinessId(),
                plan.getNombrePlan(),
                plan.getTipo(),
                plan.getTier(),
                plan.getTotalCreditos(),
                plan.getValidezDias(),
                plan.getPrecio(),
                plan.isActivo(),
                plan.getCreatedAt(),
                plan.getUpdatedAt()
        );
    }
}

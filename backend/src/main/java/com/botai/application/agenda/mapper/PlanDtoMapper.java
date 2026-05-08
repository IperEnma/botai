package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.PlanResponse;
import com.botai.domain.agenda.model.Plan;

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

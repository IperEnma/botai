package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.Plan;
import com.botai.infrastructure.agenda.persistence.entity.PlanEntity;

public final class PlanMapper {

    private PlanMapper() {
    }

    public static Plan toDomain(PlanEntity entity) {
        if (entity == null) {
            return null;
        }
        return new Plan(
                entity.getId(),
                entity.getBusinessId(),
                entity.getNombrePlan(),
                entity.getTipo(),
                entity.getTier(),
                entity.getTotalCreditos(),
                entity.getValidezDias(),
                entity.getPrecio(),
                entity.isActivo(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static PlanEntity toEntity(Plan plan) {
        if (plan == null) {
            return null;
        }
        PlanEntity entity = new PlanEntity();
        entity.setId(plan.getId());
        entity.setBusinessId(plan.getBusinessId());
        entity.setNombrePlan(plan.getNombrePlan());
        entity.setTipo(plan.getTipo());
        entity.setTier(plan.getTier());
        entity.setTotalCreditos(plan.getTotalCreditos());
        entity.setValidezDias(plan.getValidezDias());
        entity.setPrecio(plan.getPrecio());
        entity.setActivo(plan.isActivo());
        entity.setCreatedAt(plan.getCreatedAt());
        entity.setUpdatedAt(plan.getUpdatedAt());
        return entity;
    }
}

package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.BusinessHours;
import com.botai.infrastructure.agenda.persistence.entity.BusinessHoursEntity;

public final class BusinessHoursMapper {

    private BusinessHoursMapper() {}

    public static BusinessHours toDomain(BusinessHoursEntity e) {
        return new BusinessHours(e.getId(), e.getBusinessId(), e.getDiaSemana(),
                e.getApertura(), e.getCierre(), e.isCerrado());
    }

    public static BusinessHoursEntity toEntity(BusinessHours h) {
        BusinessHoursEntity e = new BusinessHoursEntity();
        e.setId(h.getId());
        e.setBusinessId(h.getBusinessId());
        e.setDiaSemana(h.getDiaSemana());
        e.setApertura(h.getApertura());
        e.setCierre(h.getCierre());
        e.setCerrado(h.isCerrado());
        return e;
    }
}

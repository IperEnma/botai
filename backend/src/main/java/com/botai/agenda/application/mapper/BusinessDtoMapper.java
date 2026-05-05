package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.BusinessResponse;
import com.botai.agenda.application.dto.BusinessSummaryResponse;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessSummary;

import java.util.List;

public final class BusinessDtoMapper {

    private BusinessDtoMapper() {
    }

    public static BusinessResponse toResponse(Business business) {
        return toResponse(business, List.of());
    }

    public static BusinessResponse toResponse(Business business, List<String> categorias) {
        if (business == null) {
            return null;
        }
        return new BusinessResponse(
                business.getId(),
                business.getTenantId(),
                business.getNombre(),
                business.getDescripcion(),
                business.getOwnerUserId(),
                business.getSearchTags(),
                business.isActivo(),
                business.getLogoUrl(),
                business.getColorPrimario(),
                business.getInstagramUrl(),
                business.getTiktokUrl(),
                business.getFacebookUrl(),
                business.getColorFondo(),
                business.getFontFamily(),
                categorias != null ? categorias : List.of()
        );
    }

    public static BusinessSummaryResponse toSummaryResponse(BusinessSummary summary) {
        if (summary == null) {
            return null;
        }
        return new BusinessSummaryResponse(
                summary.getId(),
                summary.getTenantId(),
                summary.getNombre(),
                summary.getDescripcion(),
                summary.getCategorySlugs(),
                summary.getLogoUrl()
        );
    }
}

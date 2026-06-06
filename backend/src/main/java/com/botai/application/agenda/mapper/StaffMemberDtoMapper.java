package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.domain.agenda.model.RatingSummary;
import com.botai.domain.agenda.model.StaffMember;

public final class StaffMemberDtoMapper {

    private StaffMemberDtoMapper() {
    }

    public static StaffMemberResponse toResponse(StaffMember s) {
        return toResponse(s, RatingSummary.empty());
    }

    public static StaffMemberResponse toResponse(StaffMember s, RatingSummary summary) {
        RatingSummary r = summary != null ? summary : RatingSummary.empty();
        return new StaffMemberResponse(
                s.getId(),
                s.getBusinessId(),
                s.getNombre(),
                s.getRol(),
                s.getAvatarUrl(),
                s.getTelefono(),
                s.getEmail(),
                s.getBio(),
                s.getColor(),
                s.isActivo(),
                s.getStatus(),
                s.getCustomSchedule(),
                s.getServiceIds(),
                s.getCreatedAt(),
                s.getUpdatedAt(),
                r.getAverage(),
                r.getCount()
        );
    }
}

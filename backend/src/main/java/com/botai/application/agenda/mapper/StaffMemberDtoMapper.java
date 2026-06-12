package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.domain.agenda.model.RatingSummary;
import com.botai.domain.agenda.model.StaffMember;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public final class StaffMemberDtoMapper {

    private StaffMemberDtoMapper() {
    }

    public static StaffMemberResponse toResponse(StaffMember s) {
        return toResponse(s, RatingSummary.empty());
    }

    public static StaffMemberResponse toResponse(StaffMember s, RatingSummary summary) {
        RatingSummary r = summary != null ? summary : RatingSummary.empty();
        List<UUID> businessIdsList = s.getBusinessIds() != null
                ? new ArrayList<>(s.getBusinessIds())
                : List.of();
        UUID firstBusinessId = businessIdsList.isEmpty() ? null : businessIdsList.get(0);
        return new StaffMemberResponse(
                s.getId(),
                s.getUserId(),
                firstBusinessId,
                businessIdsList,
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

package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.StaffMemberResponse;
import com.botai.agenda.domain.model.StaffMember;

public final class StaffMemberDtoMapper {

    private StaffMemberDtoMapper() {
    }

    public static StaffMemberResponse toResponse(StaffMember s) {
        return new StaffMemberResponse(
                s.getId(),
                s.getBusinessId(),
                s.getNombre(),
                s.getRol(),
                s.getAvatarUrl(),
                s.isActivo(),
                s.getCreatedAt(),
                s.getUpdatedAt()
        );
    }
}

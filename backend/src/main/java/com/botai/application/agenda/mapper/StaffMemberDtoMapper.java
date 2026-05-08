package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.domain.agenda.model.StaffMember;

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

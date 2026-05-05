package com.botai.agenda.application.usecase.staff;

import com.botai.agenda.domain.model.StaffMember;
import com.botai.agenda.domain.repository.StaffMemberRepository;

import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class ListPublicStaffUseCase {

    private final StaffMemberRepository staffMemberRepository;

    public ListPublicStaffUseCase(StaffMemberRepository staffMemberRepository) {
        this.staffMemberRepository = staffMemberRepository;
    }

    public List<StaffMember> execute(UUID businessId) {
        return staffMemberRepository.findActiveByBusinessId(businessId);
    }
}

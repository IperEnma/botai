package com.botai.application.agenda.service;

import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class ServiceStaffLookup {

    private final StaffMemberRepository staffMemberRepository;

    public ServiceStaffLookup(StaffMemberRepository staffMemberRepository) {
        this.staffMemberRepository = staffMemberRepository;
    }

    public Map<UUID, List<UUID>> staffIdsByServiceId(UUID businessId) {
        List<StaffMember> team = staffMemberRepository.findByBusinessId(businessId);
        Map<UUID, List<UUID>> byService = new HashMap<>();
        for (StaffMember member : team) {
            for (UUID serviceId : member.getServiceIds()) {
                byService.computeIfAbsent(serviceId, ignored -> new ArrayList<>())
                        .add(member.getId());
            }
        }
        return byService;
    }
}

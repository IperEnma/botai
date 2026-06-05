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
            if (!member.isActivo() || member.getDeletedAt() != null) {
                continue;
            }
            for (UUID serviceId : member.getServiceIds()) {
                byService.computeIfAbsent(serviceId, ignored -> new ArrayList<>())
                        .add(member.getId());
            }
        }
        return byService;
    }

    /**
     * Profesionales que pueden atender un servicio (asignación explícita o sin restricción).
     */
    public List<UUID> eligibleStaffForService(UUID businessId, UUID serviceId) {
        List<UUID> assigned = staffIdsByServiceId(businessId).getOrDefault(serviceId, List.of());
        if (!assigned.isEmpty()) {
            return List.copyOf(assigned);
        }
        return staffMemberRepository.findByBusinessId(businessId).stream()
                .filter(StaffMember::isActivo)
                .filter(s -> s.getDeletedAt() == null)
                .filter(s -> s.getServiceIds().isEmpty() || s.getServiceIds().contains(serviceId))
                .map(StaffMember::getId)
                .toList();
    }
}

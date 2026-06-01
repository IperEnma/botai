package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Sincroniza la relación servicio ↔ profesionales desde la configuración del servicio.
 * Actualiza {@code agenda_staff_services} en cada miembro del equipo.
 */
@org.springframework.stereotype.Service
public class AssignServiceStaffUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final StaffMemberRepository staffMemberRepository;

    public AssignServiceStaffUseCase(BusinessRepository businessRepository,
                                     ServiceRepository serviceRepository,
                                     StaffMemberRepository staffMemberRepository) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
        this.staffMemberRepository = staffMemberRepository;
    }

    @Transactional
    public void execute(String tenantId, UUID businessId, UUID serviceId, List<UUID> staffMemberIds) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        var service = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));
        if (!service.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(serviceId);
        }

        Set<UUID> desired = staffMemberIds != null
                ? new LinkedHashSet<>(staffMemberIds)
                : Set.of();

        List<StaffMember> team = staffMemberRepository.findByBusinessId(businessId);
        for (StaffMember member : team) {
            Set<UUID> current = new LinkedHashSet<>(member.getServiceIds());
            boolean shouldHave = desired.contains(member.getId());
            if (shouldHave) {
                current.add(serviceId);
            } else {
                current.remove(serviceId);
            }
            if (!current.equals(new LinkedHashSet<>(member.getServiceIds()))) {
                staffMemberRepository.updateServiceIds(member.getId(), new ArrayList<>(current));
            }
        }
    }
}

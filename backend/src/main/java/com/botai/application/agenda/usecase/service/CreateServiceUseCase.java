package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class CreateServiceUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final AssignServiceStaffUseCase assignServiceStaff;

    public CreateServiceUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository,
                                AssignServiceStaffUseCase assignServiceStaff) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
        this.assignServiceStaff = assignServiceStaff;
    }

    @Transactional
    public Service execute(String tenantId, UUID businessId,
                           String nombre, String descripcion,
                           int duracionMin, BigDecimal precio,
                           ServiceSchedulingMode schedulingMode,
                           List<UUID> staffMemberIds) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        ServiceSchedulingMode mode = schedulingMode != null
                ? schedulingMode
                : ServiceSchedulingMode.GENERAL;

        Service service = new Service(
                null, businessId, nombre, descripcion,
                duracionMin, precio, true, mode,
                null, null, null
        );
        Service saved = serviceRepository.save(service);
        if (mode == ServiceSchedulingMode.BY_STAFF && staffMemberIds != null && !staffMemberIds.isEmpty()) {
            assignServiceStaff.execute(tenantId, businessId, saved.getId(), staffMemberIds);
        }
        return saved;
    }
}

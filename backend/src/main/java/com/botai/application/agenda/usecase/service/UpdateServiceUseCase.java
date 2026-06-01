package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class UpdateServiceUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final AssignServiceStaffUseCase assignServiceStaff;

    public UpdateServiceUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository,
                                AssignServiceStaffUseCase assignServiceStaff) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
        this.assignServiceStaff = assignServiceStaff;
    }

    @Transactional
    public Service execute(String tenantId, UUID businessId, UUID serviceId,
                           String nombre, String descripcion,
                           int duracionMin, BigDecimal precio, boolean activo,
                           ServiceSchedulingMode schedulingMode,
                           List<UUID> staffMemberIds) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Service existing = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));

        if (!existing.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(serviceId);
        }

        ServiceSchedulingMode mode = schedulingMode != null
                ? schedulingMode
                : existing.getSchedulingMode();

        Service saved = serviceRepository.save(new Service(
                existing.getId(), businessId, nombre, descripcion,
                duracionMin, precio, activo, mode,
                existing.getDeletedAt(), existing.getCreatedAt(), existing.getUpdatedAt()
        ));

        if (staffMemberIds != null) {
            if (mode == ServiceSchedulingMode.BY_STAFF) {
                assignServiceStaff.execute(tenantId, businessId, serviceId, staffMemberIds);
            } else {
                assignServiceStaff.execute(tenantId, businessId, serviceId, List.of());
            }
        } else if (mode == ServiceSchedulingMode.GENERAL) {
            assignServiceStaff.execute(tenantId, businessId, serviceId, List.of());
        }

        return saved;
    }
}

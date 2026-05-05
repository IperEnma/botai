package com.botai.agenda.application.usecase.service;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.ServiceNotFoundException;
import com.botai.agenda.domain.model.Service;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.ServiceRepository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@org.springframework.stereotype.Service
public class UpdateServiceUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;

    public UpdateServiceUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
    }

    @Transactional
    public Service execute(String tenantId, UUID businessId, UUID serviceId,
                           String nombre, String descripcion,
                           int duracionMin, BigDecimal precio, boolean activo) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Service existing = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));

        if (!existing.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(serviceId);
        }

        return serviceRepository.save(new Service(
                existing.getId(), businessId, nombre, descripcion,
                duracionMin, precio, activo,
                existing.getDeletedAt(), existing.getCreatedAt(), existing.getUpdatedAt()
        ));
    }
}

package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@org.springframework.stereotype.Service
public class CreateServiceUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;

    public CreateServiceUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
    }

    @Transactional
    public Service execute(String tenantId, UUID businessId,
                           String nombre, String descripcion,
                           int duracionMin, BigDecimal precio) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Service service = new Service(
                null, businessId, nombre, descripcion,
                duracionMin, precio, true,
                null, null, null
        );
        return serviceRepository.save(service);
    }
}

package com.botai.agenda.application.usecase.service;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.ServiceNotFoundException;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.ServiceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class DeleteServiceUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;

    public DeleteServiceUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
    }

    @Transactional
    public void execute(String tenantId, UUID businessId, UUID serviceId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        com.botai.agenda.domain.model.Service service = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));

        if (!service.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(serviceId);
        }

        serviceRepository.softDelete(serviceId);
    }
}

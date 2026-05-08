package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@org.springframework.stereotype.Service
public class ListBusinessServicesUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;

    public ListBusinessServicesUseCase(BusinessRepository businessRepository,
                                       ServiceRepository serviceRepository) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
    }

    /** Uso público (no valida tenant). */
    @Transactional(readOnly = true)
    public List<Service> execute(UUID businessId) {
        return serviceRepository.findAllActiveByBusinessId(businessId);
    }

    /** Uso admin de tenant. Valida que el negocio pertenezca al tenant. */
    @Transactional(readOnly = true)
    public List<Service> execute(String tenantId, UUID businessId, boolean soloActivos) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        return soloActivos
                ? serviceRepository.findAllActiveByBusinessId(businessId)
                : serviceRepository.findAllByBusinessId(businessId);
    }
}

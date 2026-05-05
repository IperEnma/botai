package com.botai.agenda.application.usecase.business;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.repository.BusinessRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Lista y detalle de negocios dentro del scope de un tenant. */
@Service
public class ListBusinessesByTenantUseCase {

    private final BusinessRepository businessRepository;

    public ListBusinessesByTenantUseCase(BusinessRepository businessRepository) {
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public List<Business> listAll(String tenantId) {
        return businessRepository.findAllByTenantId(tenantId);
    }

    @Transactional(readOnly = true)
    public Business findOne(String tenantId, UUID businessId) {
        return businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }
}

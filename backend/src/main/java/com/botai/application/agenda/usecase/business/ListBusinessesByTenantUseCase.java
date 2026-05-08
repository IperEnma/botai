package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
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

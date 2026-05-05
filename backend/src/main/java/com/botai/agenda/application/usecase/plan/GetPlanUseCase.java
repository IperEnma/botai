package com.botai.agenda.application.usecase.plan;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.PlanDoesNotBelongToBusinessException;
import com.botai.agenda.domain.exception.PlanNotFoundException;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.PlanRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class GetPlanUseCase {

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;

    public GetPlanUseCase(PlanRepository planRepository,
                          BusinessRepository businessRepository) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public Plan execute(String tenantId, UUID businessId, UUID planId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Plan plan = planRepository.findById(planId)
                .orElseThrow(() -> new PlanNotFoundException(planId));
        if (!plan.getBusinessId().equals(businessId)) {
            throw new PlanDoesNotBelongToBusinessException(planId, businessId);
        }
        return plan;
    }
}

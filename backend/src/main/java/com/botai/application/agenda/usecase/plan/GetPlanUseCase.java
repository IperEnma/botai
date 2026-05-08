package com.botai.application.agenda.usecase.plan;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.PlanRepository;
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

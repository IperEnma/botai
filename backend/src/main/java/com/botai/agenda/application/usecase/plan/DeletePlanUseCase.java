package com.botai.agenda.application.usecase.plan;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.PlanDoesNotBelongToBusinessException;
import com.botai.agenda.domain.exception.PlanNotFoundException;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.PlanRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Soft delete del plan: establece {@code deleted_at} y desactiva el plan.
 * No se borra físicamente porque puede haber suscripciones existentes referenciando
 * el plan vía FK {@code RESTRICT}.
 */
@Service
public class DeletePlanUseCase {

    private static final Logger log = LoggerFactory.getLogger(DeletePlanUseCase.class);

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;

    public DeletePlanUseCase(PlanRepository planRepository,
                             BusinessRepository businessRepository) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public void execute(String tenantId, UUID businessId, UUID planId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Plan existing = planRepository.findById(planId)
                .orElseThrow(() -> new PlanNotFoundException(planId));
        if (!existing.getBusinessId().equals(businessId)) {
            throw new PlanDoesNotBelongToBusinessException(planId, businessId);
        }

        planRepository.softDelete(planId);
        log.info("AGENDA: plan eliminado (soft delete) id={} businessId={}", planId, businessId);
    }
}

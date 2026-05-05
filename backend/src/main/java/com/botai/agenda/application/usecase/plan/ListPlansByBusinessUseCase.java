package com.botai.agenda.application.usecase.plan;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.PlanRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Lista planes de un negocio del tenant.
 *
 * <p>Si {@code onlyActive=true}, devuelve solo los planes con {@code activo=true}.
 * Esto le sirve al admin para alternar entre "mostrar catálogo vigente" vs
 * "ver todo el historial, incluidos los dados de baja".</p>
 */
@Service
public class ListPlansByBusinessUseCase {

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;

    public ListPlansByBusinessUseCase(PlanRepository planRepository,
                                      BusinessRepository businessRepository) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public List<Plan> execute(String tenantId, UUID businessId, boolean onlyActive) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        return onlyActive
                ? planRepository.findAllActiveByBusinessId(businessId)
                : planRepository.findAllByBusinessId(businessId);
    }
}

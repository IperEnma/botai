package com.botai.application.agenda.usecase.plan;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Actualiza un plan (PATCH — {@code null} significa "no cambiar"). El cambio
 * de {@code tipo} y {@code totalCreditos} se valida en conjunto con la misma
 * regla que {@link CreatePlanUseCase}.
 */
@Service
public class UpdatePlanUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdatePlanUseCase.class);

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;

    public UpdatePlanUseCase(PlanRepository planRepository,
                             BusinessRepository businessRepository) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public Plan execute(String tenantId,
                        UUID businessId,
                        UUID planId,
                        String nombrePlan,
                        PlanTipo tipo,
                        PlanTier tier,
                        Integer totalCreditos,
                        Integer validezDias,
                        BigDecimal precio,
                        Boolean activo) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Plan existing = planRepository.findById(planId)
                .orElseThrow(() -> new PlanNotFoundException(planId));
        if (!existing.getBusinessId().equals(businessId)) {
            throw new PlanDoesNotBelongToBusinessException(planId, businessId);
        }

        PlanTipo nuevoTipo = tipo == null ? existing.getTipo() : tipo;
        Integer nuevosCreditos = totalCreditos == null ? existing.getTotalCreditos() : totalCreditos;
        // Si cambió el tipo, igual re-validamos; si no, validamos por si cambiaron los créditos.
        CreatePlanUseCase.validarCreditosSegunTipo(nuevoTipo, nuevosCreditos);

        Plan merged = new Plan(
                existing.getId(),
                existing.getBusinessId(),
                nombrePlan == null ? existing.getNombrePlan() : nombrePlan,
                nuevoTipo,
                tier == null ? existing.getTier() : tier,
                nuevosCreditos,
                validezDias == null ? existing.getValidezDias() : validezDias,
                precio == null ? existing.getPrecio() : precio,
                activo == null ? existing.isActivo() : activo,
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
        Plan saved = planRepository.save(merged);
        log.info("AGENDA: plan actualizado id={} businessId={}", saved.getId(), businessId);
        return saved;
    }
}

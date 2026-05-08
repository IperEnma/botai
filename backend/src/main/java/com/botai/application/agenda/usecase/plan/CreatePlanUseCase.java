package com.botai.application.agenda.usecase.plan;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.InvalidPlanConfigurationException;
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
 * Crea un plan nuevo para un negocio del tenant. Valida reglas de consistencia
 * entre {@code tipo} y {@code totalCreditos} para evitar configuraciones
 * ambiguas que el {@code CreditDomainService} no podría interpretar.
 */
@Service
public class CreatePlanUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreatePlanUseCase.class);

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;

    public CreatePlanUseCase(PlanRepository planRepository,
                             BusinessRepository businessRepository) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public Plan execute(String tenantId,
                        UUID businessId,
                        String nombrePlan,
                        PlanTipo tipo,
                        PlanTier tier,
                        Integer totalCreditos,
                        int validezDias,
                        BigDecimal precio,
                        boolean activo) {
        // Valida que el negocio exista y pertenezca al tenant.
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        validarCreditosSegunTipo(tipo, totalCreditos);

        Plan plan = new Plan(
                null, businessId, nombrePlan, tipo, tier, totalCreditos,
                validezDias, precio, activo, null, null
        );
        Plan saved = planRepository.save(plan);
        log.info("AGENDA: plan creado id={} businessId={} tipo={}", saved.getId(), businessId, tipo);
        return saved;
    }

    /**
     * Reglas de consistencia tipo/créditos (ver {@link PlanTipo}):
     * <ul>
     *   <li>{@code POR_CREDITOS}/{@code MIXTO} requieren {@code totalCreditos > 0}.</li>
     *   <li>{@code ILIMITADO_MENSUAL}/{@code SOLO_RESERVA} no admiten créditos
     *       declarados.</li>
     * </ul>
     */
    static void validarCreditosSegunTipo(PlanTipo tipo, Integer totalCreditos) {
        switch (tipo) {
            case POR_CREDITOS, MIXTO -> {
                if (totalCreditos == null || totalCreditos <= 0) {
                    throw new InvalidPlanConfigurationException(
                            "El tipo " + tipo + " requiere totalCreditos > 0");
                }
            }
            case ILIMITADO_MENSUAL, SOLO_RESERVA -> {
                if (totalCreditos != null && totalCreditos != 0) {
                    throw new InvalidPlanConfigurationException(
                            "El tipo " + tipo + " no admite totalCreditos (dejar null o 0)");
                }
            }
        }
    }
}

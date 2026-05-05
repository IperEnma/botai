package com.botai.agenda.application.usecase.plan;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.PlanDoesNotBelongToBusinessException;
import com.botai.agenda.domain.exception.PlanNotFoundException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.model.PlanTier;
import com.botai.agenda.domain.model.PlanTipo;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.PlanRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GetPlanUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private GetPlanUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final UUID planId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.of(2026, 1, 1, 10, 0);

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new GetPlanUseCase(planRepository, businessRepository);
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "N", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
    }

    private Plan plan(UUID planBusinessId) {
        return new Plan(planId, planBusinessId, "x", PlanTipo.POR_CREDITOS,
                PlanTier.PLATA, 10, 30, new BigDecimal("10.00"), true, now, now);
    }

    @Test
    void devuelvePlanCuandoPerteneceAlNegocio() {
        Plan p = plan(businessId);
        when(planRepository.findById(planId)).thenReturn(Optional.of(p));

        Plan result = useCase.execute(tenantId, businessId, planId);

        assertEquals(planId, result.getId());
        assertEquals(businessId, result.getBusinessId());
    }

    @Test
    void lanza404CuandoElNegocioNoPertenceAlTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId));
    }

    @Test
    void lanza404CuandoElPlanNoExiste() {
        when(planRepository.findById(planId)).thenReturn(Optional.empty());

        assertThrows(PlanNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId));
    }

    @Test
    void lanza404CuandoElPlanPerteneceAOtroNegocio() {
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(UUID.randomUUID())));

        assertThrows(PlanDoesNotBelongToBusinessException.class,
                () -> useCase.execute(tenantId, businessId, planId));
    }
}

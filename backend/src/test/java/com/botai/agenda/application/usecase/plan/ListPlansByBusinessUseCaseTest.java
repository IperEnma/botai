package com.botai.agenda.application.usecase.plan;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
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
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListPlansByBusinessUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private ListPlansByBusinessUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.of(2026, 1, 1, 10, 0);

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new ListPlansByBusinessUseCase(planRepository, businessRepository);
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "N", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
    }

    private Plan somePlan() {
        return new Plan(UUID.randomUUID(), businessId, "x", PlanTipo.POR_CREDITOS,
                PlanTier.PLATA, 10, 30, new BigDecimal("10.00"), true, now, now);
    }

    @Test
    void listaTodosCuandoOnlyActiveEsFalse() {
        List<Plan> all = List.of(somePlan(), somePlan());
        when(planRepository.findAllByBusinessId(businessId)).thenReturn(all);

        List<Plan> result = useCase.execute(tenantId, businessId, false);

        assertEquals(2, result.size());
        verify(planRepository).findAllByBusinessId(businessId);
    }

    @Test
    void listaSoloActivosCuandoOnlyActiveEsTrue() {
        List<Plan> active = List.of(somePlan());
        when(planRepository.findAllActiveByBusinessId(businessId)).thenReturn(active);

        List<Plan> result = useCase.execute(tenantId, businessId, true);

        assertEquals(1, result.size());
        verify(planRepository).findAllActiveByBusinessId(businessId);
    }

    @Test
    void lanza404CuandoElNegocioNoPertenceAlTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, false));
    }
}

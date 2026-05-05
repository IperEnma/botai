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

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DeletePlanUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private DeletePlanUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final UUID planId = UUID.randomUUID();
    private final LocalDateTime created = LocalDateTime.of(2026, 1, 1, 10, 0);
    private final LocalDateTime updated = LocalDateTime.of(2026, 1, 2, 10, 0);

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new DeletePlanUseCase(planRepository, businessRepository);
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "N", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
    }

    private Plan plan() {
        return new Plan(planId, businessId, "10 sesiones",
                PlanTipo.POR_CREDITOS, PlanTier.PLATA, 10, 30,
                new BigDecimal("15000.00"), true, created, updated);
    }

    @Test
    void softDeleteLlamaAlRepositorio() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(plan()));

        useCase.execute(tenantId, businessId, planId);

        verify(planRepository).softDelete(planId);
    }

    @Test
    void lanza404CuandoElNegocioNoPertenceAlTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId));
        verify(planRepository, never()).softDelete(planId);
    }

    @Test
    void lanza404CuandoElPlanNoExiste() {
        when(planRepository.findById(planId)).thenReturn(Optional.empty());

        assertThrows(PlanNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId));
        verify(planRepository, never()).softDelete(planId);
    }

    @Test
    void lanza404CuandoElPlanPerteneceAOtroNegocio() {
        UUID otherBusiness = UUID.randomUUID();
        Plan foreign = new Plan(planId, otherBusiness, "Otro", PlanTipo.SOLO_RESERVA,
                null, null, 15, new BigDecimal("0.00"), true, created, updated);
        when(planRepository.findById(planId)).thenReturn(Optional.of(foreign));

        assertThrows(PlanDoesNotBelongToBusinessException.class,
                () -> useCase.execute(tenantId, businessId, planId));
        verify(planRepository, never()).softDelete(planId);
    }
}

package com.botai.application.agenda.usecase.plan;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.InvalidPlanConfigurationException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UpdatePlanUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private UpdatePlanUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final UUID planId = UUID.randomUUID();
    private final LocalDateTime created = LocalDateTime.of(2026, 1, 1, 10, 0);
    private final LocalDateTime updated = LocalDateTime.of(2026, 1, 2, 10, 0);

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new UpdatePlanUseCase(planRepository, businessRepository);
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "N", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
        when(planRepository.save(any(Plan.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private Plan existingPorCreditos() {
        return new Plan(planId, businessId, "10 sesiones",
                PlanTipo.POR_CREDITOS, PlanTier.PLATA, 10, 30,
                new BigDecimal("15000.00"), true, created, updated);
    }

    @Test
    void patchSoloActualizaLoProvisto() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(existingPorCreditos()));

        useCase.execute(tenantId, businessId, planId,
                "Nuevo nombre", null, null, null, null, null, null);

        ArgumentCaptor<Plan> captor = ArgumentCaptor.forClass(Plan.class);
        verify(planRepository).save(captor.capture());
        Plan saved = captor.getValue();

        assertEquals("Nuevo nombre", saved.getNombrePlan());
        assertEquals(PlanTipo.POR_CREDITOS, saved.getTipo());
        assertEquals(PlanTier.PLATA, saved.getTier());
        assertEquals(10, saved.getTotalCreditos());
        assertEquals(30, saved.getValidezDias());
        assertEquals(new BigDecimal("15000.00"), saved.getPrecio());
        assertTrue(saved.isActivo());
        assertEquals(created, saved.getCreatedAt(), "createdAt se preserva");
    }

    @Test
    void puedeCambiarTipoAIlimitadoSiSeLimpianLosCreditos() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(existingPorCreditos()));

        // Cambiar tipo a ILIMITADO y explícitamente pasar créditos=0 → válido.
        useCase.execute(tenantId, businessId, planId,
                null, PlanTipo.ILIMITADO_MENSUAL, null,
                0, null, null, null);

        ArgumentCaptor<Plan> captor = ArgumentCaptor.forClass(Plan.class);
        verify(planRepository).save(captor.capture());
        Plan saved = captor.getValue();

        assertEquals(PlanTipo.ILIMITADO_MENSUAL, saved.getTipo());
        assertEquals(0, saved.getTotalCreditos());
    }

    @Test
    void permiteDesactivarPlan() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(existingPorCreditos()));

        useCase.execute(tenantId, businessId, planId,
                null, null, null, null, null, null, false);

        ArgumentCaptor<Plan> captor = ArgumentCaptor.forClass(Plan.class);
        verify(planRepository).save(captor.capture());
        assertFalse(captor.getValue().isActivo());
    }

    @Test
    void validaConsistenciaTipoCreditosAlCambiarTotalCreditos() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(existingPorCreditos()));

        // Cambiar tipo a ILIMITADO sin limpiar créditos → inválido.
        assertThrows(InvalidPlanConfigurationException.class,
                () -> useCase.execute(tenantId, businessId, planId,
                        null, PlanTipo.ILIMITADO_MENSUAL, null, null, null, null, null));
        verify(planRepository, never()).save(any(Plan.class));
    }

    @Test
    void lanza404CuandoElNegocioNoPertenceAlTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId,
                        "x", null, null, null, null, null, null));
    }

    @Test
    void lanza404CuandoElPlanNoExiste() {
        when(planRepository.findById(planId)).thenReturn(Optional.empty());

        assertThrows(PlanNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, planId,
                        "x", null, null, null, null, null, null));
    }

    @Test
    void lanza404CuandoElPlanPerteneceAOtroNegocio() {
        UUID otherBusiness = UUID.randomUUID();
        Plan foreignPlan = new Plan(planId, otherBusiness, "Otro", PlanTipo.SOLO_RESERVA,
                null, null, 15, new BigDecimal("0.00"), true, created, updated);
        when(planRepository.findById(planId)).thenReturn(Optional.of(foreignPlan));

        assertThrows(PlanDoesNotBelongToBusinessException.class,
                () -> useCase.execute(tenantId, businessId, planId,
                        "x", null, null, null, null, null, null));
        verify(planRepository, never()).save(any(Plan.class));
    }
}

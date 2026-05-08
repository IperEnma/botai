package com.botai.application.agenda.usecase.plan;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.InvalidPlanConfigurationException;
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
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CreatePlanUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private CreatePlanUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new CreatePlanUseCase(planRepository, businessRepository);
        when(planRepository.save(any(Plan.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private void businessExists() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "Gym Andes", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
    }

    @Test
    void creaPlanPorCreditosValido() {
        businessExists();

        Plan saved = useCase.execute(
                tenantId, businessId,
                "10 sesiones",
                PlanTipo.POR_CREDITOS,
                PlanTier.PLATA,
                10,
                30,
                new BigDecimal("15000.00"),
                true
        );

        ArgumentCaptor<Plan> captor = ArgumentCaptor.forClass(Plan.class);
        verify(planRepository).save(captor.capture());
        Plan captured = captor.getValue();

        assertEquals(businessId, captured.getBusinessId());
        assertEquals(PlanTipo.POR_CREDITOS, captured.getTipo());
        assertEquals(PlanTier.PLATA, captured.getTier());
        assertEquals(10, captured.getTotalCreditos());
        assertEquals(30, captured.getValidezDias());
        assertTrue(captured.isActivo());
        assertEquals(businessId, saved.getBusinessId());
    }

    @Test
    void creaPlanIlimitadoSinCreditos() {
        businessExists();

        useCase.execute(
                tenantId, businessId,
                "Ilimitado Mensual",
                PlanTipo.ILIMITADO_MENSUAL,
                PlanTier.VIP,
                null,
                30,
                new BigDecimal("30000.00"),
                true
        );

        ArgumentCaptor<Plan> captor = ArgumentCaptor.forClass(Plan.class);
        verify(planRepository).save(captor.capture());
        assertEquals(PlanTipo.ILIMITADO_MENSUAL, captor.getValue().getTipo());
    }

    @Test
    void rechazaPorCreditosSinCreditos() {
        businessExists();

        InvalidPlanConfigurationException ex = assertThrows(InvalidPlanConfigurationException.class,
                () -> useCase.execute(
                        tenantId, businessId, "Mal plan",
                        PlanTipo.POR_CREDITOS, null,
                        null,               // ← null para POR_CREDITOS es inválido
                        30, new BigDecimal("10.00"), true));

        assertTrue(ex.getMessage().contains("POR_CREDITOS"));
        verify(planRepository, never()).save(any(Plan.class));
    }

    @Test
    void rechazaIlimitadoConCreditosDeclarados() {
        businessExists();

        assertThrows(InvalidPlanConfigurationException.class,
                () -> useCase.execute(
                        tenantId, businessId, "Mal ilimitado",
                        PlanTipo.ILIMITADO_MENSUAL, null,
                        5,                  // ← con créditos para ilimitado es inválido
                        30, new BigDecimal("10.00"), true));

        verify(planRepository, never()).save(any(Plan.class));
    }

    @Test
    void rechazaCuandoElNegocioNoExisteParaElTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(
                        tenantId, businessId, "x",
                        PlanTipo.SOLO_RESERVA, null, null,
                        30, new BigDecimal("0.00"), true));

        verify(planRepository, never()).save(any(Plan.class));
    }
}

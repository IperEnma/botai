package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.PaymentFailedException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotActiveException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.CreditMotivo;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import com.botai.domain.agenda.service.PaymentPort;
import com.botai.domain.agenda.service.PaymentResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PurchaseSubscriptionUseCaseTest {

    private PlanRepository planRepository;
    private BusinessRepository businessRepository;
    private UserSubscriptionRepository subscriptionRepository;
    private CreditTransactionRepository transactionRepository;
    private PaymentPort paymentPort;
    private Clock clock;
    private PurchaseSubscriptionUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();
    private final UUID planId = UUID.randomUUID();
    private final Instant frozen = Instant.parse("2026-04-20T10:00:00Z");

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        businessRepository = mock(BusinessRepository.class);
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        transactionRepository = mock(CreditTransactionRepository.class);
        paymentPort = mock(PaymentPort.class);
        clock = Clock.fixed(frozen, ZoneOffset.UTC);

        useCase = new PurchaseSubscriptionUseCase(
                planRepository, businessRepository, subscriptionRepository,
                transactionRepository, paymentPort, clock);

        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "N", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
        when(subscriptionRepository.save(any(UserSubscription.class)))
                .thenAnswer(inv -> {
                    UserSubscription in = inv.getArgument(0);
                    // Simulo que la DB asigna id y timestamps.
                    return new UserSubscription(
                            UUID.randomUUID(), in.getUserId(), in.getPlanId(), in.getBusinessId(),
                            in.getSaldoActual(), in.getFechaInicio(), in.getFechaExpiracion(),
                            in.getEstado(), LocalDateTime.now(clock), LocalDateTime.now(clock));
                });
    }

    private Plan planPorCreditos(boolean activo) {
        return new Plan(planId, businessId, "10 sesiones",
                PlanTipo.POR_CREDITOS, PlanTier.PLATA, 10, 30,
                new BigDecimal("15000.00"), activo, null, null);
    }

    private Plan planIlimitado() {
        return new Plan(planId, businessId, "Ilimitado",
                PlanTipo.ILIMITADO_MENSUAL, PlanTier.VIP, null, 30,
                new BigDecimal("30000.00"), true, null, null);
    }

    @Test
    void compraPlanPorCreditosCreaSuscripcionYTransaccion() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(planPorCreditos(true)));
        when(paymentPort.charge(eq(userId), eq(new BigDecimal("15000.00")), eq("ARS"), anyString()))
                .thenReturn(PaymentResult.ok("stub-tx-1"));

        UserSubscription result = useCase.execute(tenantId, businessId, userId, planId);

        // La suscripción arrancó con el saldo = totalCreditos del plan.
        ArgumentCaptor<UserSubscription> subCap = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptionRepository).save(subCap.capture());
        UserSubscription savedSub = subCap.getValue();
        assertEquals(10, savedSub.getSaldoActual());
        assertEquals(SubscriptionEstado.ACTIVE, savedSub.getEstado());
        assertEquals(businessId, savedSub.getBusinessId());
        assertEquals(userId, savedSub.getUserId());
        // Vigencia = now + 30 días.
        LocalDateTime now = LocalDateTime.ofInstant(frozen, ZoneId.of("UTC"));
        assertEquals(now, savedSub.getFechaInicio());
        assertEquals(now.plusDays(30), savedSub.getFechaExpiracion());

        // Se registró el movimiento de compra con el monto inicial.
        ArgumentCaptor<CreditTransaction> txCap = ArgumentCaptor.forClass(CreditTransaction.class);
        verify(transactionRepository).save(txCap.capture());
        CreditTransaction tx = txCap.getValue();
        assertEquals(10, tx.getMonto());
        assertEquals(CreditMotivo.COMPRA, tx.getMotivo());
        assertEquals(result.getId(), tx.getSubscriptionId());
    }

    @Test
    void compraIlimitadoNoRegistraTransaccionDeCreditos() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(planIlimitado()));
        when(paymentPort.charge(any(), any(), anyString(), anyString()))
                .thenReturn(PaymentResult.ok("stub-tx-2"));

        UserSubscription result = useCase.execute(tenantId, businessId, userId, planId);

        assertEquals(0, result.getSaldoActual());
        // Los ilimitados no cargan libro mayor al comprar: no hay créditos que mover.
        verify(transactionRepository, never()).save(any(CreditTransaction.class));
    }

    @Test
    void rechazaCompraSiElPagoFalla() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(planPorCreditos(true)));
        when(paymentPort.charge(any(), any(), anyString(), anyString()))
                .thenReturn(PaymentResult.rejected("CARD_DECLINED"));

        PaymentFailedException ex = assertThrows(PaymentFailedException.class,
                () -> useCase.execute(tenantId, businessId, userId, planId));
        assertEquals("CARD_DECLINED", ex.getReason());
        verify(subscriptionRepository, never()).save(any(UserSubscription.class));
        verify(transactionRepository, never()).save(any(CreditTransaction.class));
    }

    @Test
    void rechazaCompraSiElPlanEstaInactivo() {
        when(planRepository.findById(planId)).thenReturn(Optional.of(planPorCreditos(false)));

        assertThrows(PlanNotActiveException.class,
                () -> useCase.execute(tenantId, businessId, userId, planId));
        // Ni siquiera llegamos a cobrar.
        verify(paymentPort, never()).charge(any(), any(), anyString(), anyString());
        verify(subscriptionRepository, never()).save(any(UserSubscription.class));
    }

    @Test
    void lanza404CuandoElNegocioNoPertenceAlTenant() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, userId, planId));
        verify(paymentPort, never()).charge(any(), any(), anyString(), anyString());
    }

    @Test
    void lanza404CuandoElPlanNoExiste() {
        when(planRepository.findById(planId)).thenReturn(Optional.empty());

        assertThrows(PlanNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, userId, planId));
    }

    @Test
    void lanza404CuandoElPlanPerteneceAOtroNegocio() {
        UUID otherBusiness = UUID.randomUUID();
        Plan foreign = new Plan(planId, otherBusiness, "x", PlanTipo.SOLO_RESERVA,
                null, null, 15, new BigDecimal("0.00"), true, null, null);
        when(planRepository.findById(planId)).thenReturn(Optional.of(foreign));

        assertThrows(PlanDoesNotBelongToBusinessException.class,
                () -> useCase.execute(tenantId, businessId, userId, planId));
        verify(paymentPort, never()).charge(any(), any(), anyString(), anyString());
    }
}

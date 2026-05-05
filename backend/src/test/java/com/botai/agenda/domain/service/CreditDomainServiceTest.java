package com.botai.agenda.domain.service;

import com.botai.agenda.domain.exception.NoCreditsException;
import com.botai.agenda.domain.exception.SubscriptionExpiredException;
import com.botai.agenda.domain.model.CreditMotivo;
import com.botai.agenda.domain.model.Plan;
import com.botai.agenda.domain.model.PlanTier;
import com.botai.agenda.domain.model.PlanTipo;
import com.botai.agenda.domain.model.SubscriptionEstado;
import com.botai.agenda.domain.model.UserSubscription;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests unitarios de {@link CreditDomainService}. No necesitan Spring ni mocks:
 * el service es puro (recibe objetos, devuelve objetos).
 */
class CreditDomainServiceTest {

    private CreditDomainService service;
    private LocalDateTime now;

    @BeforeEach
    void setUp() {
        service = new CreditDomainService();
        now = LocalDateTime.of(2026, 4, 20, 10, 0);
    }

    // ── descontarPorReserva ─────────────────────────────────────────────────

    @Test
    void descontarReducePorUnoEnPlanPorCreditos() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);
        UUID bookingId = UUID.randomUUID();

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, bookingId, now);

        assertEquals(4, result.subscription().getSaldoActual(),
                "Saldo debe haberse descontado 1");
        assertEquals(-1, result.transaction().getMonto(),
                "Monto de la tx debe ser -1");
        assertEquals(CreditMotivo.RESERVA, result.transaction().getMotivo());
        assertEquals(sub.getId(), result.transaction().getSubscriptionId());
        assertEquals(bookingId, result.transaction().getBookingId());
    }

    @Test
    void descontarReducePorUnoEnPlanMixto() {
        UserSubscription sub = subWithSaldo(1, SubscriptionEstado.ACTIVE, now.plusDays(1));
        Plan plan = plan(PlanTipo.MIXTO, 10);

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, null, now);

        assertEquals(0, result.subscription().getSaldoActual());
        assertEquals(-1, result.transaction().getMonto());
    }

    @Test
    void descontarEnIlimitadoNoTocaSaldoPeroEmiteTxDeTrazabilidad() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(30));
        Plan plan = plan(PlanTipo.ILIMITADO_MENSUAL, null);

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, null, now);

        assertEquals(0, result.subscription().getSaldoActual(),
                "En ilimitado el saldo no se toca");
        assertEquals(0, result.transaction().getMonto(),
                "Monto=0 para que el libro mayor refleje el uso sin descontar");
        assertEquals(CreditMotivo.RESERVA, result.transaction().getMotivo());
    }

    @Test
    void descontarEnSoloReservaNoTocaSaldo() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(5));
        Plan plan = plan(PlanTipo.SOLO_RESERVA, null);

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, null, now);

        assertEquals(0, result.subscription().getSaldoActual());
        assertEquals(0, result.transaction().getMonto());
    }

    @Test
    void descontarSinSaldoEnPlanPorCreditosTiraNoCreditsException() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);

        assertThrows(NoCreditsException.class,
                () -> service.descontarPorReserva(sub, plan, null, now));
    }

    @Test
    void descontarSobreSuscripcionVencidaTiraSubscriptionExpired() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.ACTIVE, now.minusDays(1));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);

        assertThrows(SubscriptionExpiredException.class,
                () -> service.descontarPorReserva(sub, plan, null, now));
    }

    @Test
    void descontarSobreSuscripcionNoActivaTiraSubscriptionExpired() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.CANCELLED, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);

        assertThrows(SubscriptionExpiredException.class,
                () -> service.descontarPorReserva(sub, plan, null, now));
    }

    // ── devolverPorCancelacion ─────────────────────────────────────────────

    @Test
    void devolverSumaUnoEnPlanPorCreditos() {
        UserSubscription sub = subWithSaldo(3, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);
        UUID bookingId = UUID.randomUUID();

        CreditDomainService.CreditDebit result = service.devolverPorCancelacion(sub, plan, bookingId);

        assertEquals(4, result.subscription().getSaldoActual());
        assertEquals(1, result.transaction().getMonto());
        assertEquals(CreditMotivo.CANCELACION_DEVUELTA, result.transaction().getMotivo());
        assertEquals(bookingId, result.transaction().getBookingId());
    }

    @Test
    void devolverSumaUnoEnPlanMixto() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.MIXTO, 10);

        CreditDomainService.CreditDebit result = service.devolverPorCancelacion(sub, plan, null);

        assertEquals(1, result.subscription().getSaldoActual());
        assertEquals(1, result.transaction().getMonto());
    }

    @Test
    void devolverEnIlimitadoNoSumaPeroEmiteTxConMontoCero() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.ILIMITADO_MENSUAL, null);

        CreditDomainService.CreditDebit result = service.devolverPorCancelacion(sub, plan, null);

        assertEquals(0, result.subscription().getSaldoActual());
        assertEquals(0, result.transaction().getMonto());
        assertEquals(CreditMotivo.CANCELACION_DEVUELTA, result.transaction().getMotivo());
    }

    @Test
    void devolverEnSoloReservaNoSumaSaldo() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.SOLO_RESERVA, null);

        CreditDomainService.CreditDebit result = service.devolverPorCancelacion(sub, plan, null);

        assertEquals(0, result.subscription().getSaldoActual());
        assertEquals(0, result.transaction().getMonto());
    }

    // ── validarVigencia ────────────────────────────────────────────────────

    @Test
    void validarVigenciaOkParaSubActivaYNoVencida() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.ACTIVE, now.plusDays(1));
        // No debe tirar:
        service.validarVigencia(sub, now);
    }

    @Test
    void validarVigenciaTiraSiFechaExpiracionEsPasada() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.ACTIVE, now.minusSeconds(1));
        assertThrows(SubscriptionExpiredException.class,
                () -> service.validarVigencia(sub, now));
    }

    @Test
    void validarVigenciaTiraSiEstadoNoEsActive() {
        UserSubscription sub = subWithSaldo(5, SubscriptionEstado.EXPIRED, now.plusDays(10));
        assertThrows(SubscriptionExpiredException.class,
                () -> service.validarVigencia(sub, now));
    }

    // ── Invariantes extra ──────────────────────────────────────────────────

    @Test
    void descontarDevuelveTxConBookingIdNullCuandoNoHayBooking() {
        UserSubscription sub = subWithSaldo(2, SubscriptionEstado.ACTIVE, now.plusDays(1));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, null, now);

        assertNull(result.transaction().getBookingId(),
                "Si no viene bookingId en el descuento, la tx lo refleja null");
    }

    @Test
    void descontarUltimoCredito_saldoQuedaEnCero() {
        UserSubscription sub = subWithSaldo(1, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 5);

        CreditDomainService.CreditDebit result = service.descontarPorReserva(sub, plan, null, now);

        assertEquals(0, result.subscription().getSaldoActual(),
                "Último crédito: saldo queda en 0, no negativo");
        assertEquals(-1, result.transaction().getMonto());
    }

    @Test
    void descontarConSaldoCeroEnPlanMixtoTiraNoCredits() {
        UserSubscription sub = subWithSaldo(0, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.MIXTO, 5);

        assertThrows(NoCreditsException.class,
                () -> service.descontarPorReserva(sub, plan, null, now));
    }

    @Test
    void validarVigenciaOkCuandoExpiranExactamenteAhora() {
        // fechaExpiracion == now → isBefore(now) == false → la sub sigue vigente
        UserSubscription sub = subWithSaldo(1, SubscriptionEstado.ACTIVE, now);

        // No debe tirar:
        service.validarVigencia(sub, now);
    }

    @Test
    void devolverPreservaInmutabilidadDeLaSuscripcion() {
        UserSubscription original = subWithSaldo(3, SubscriptionEstado.ACTIVE, now.plusDays(10));
        Plan plan = plan(PlanTipo.POR_CREDITOS, 10);

        CreditDomainService.CreditDebit result = service.devolverPorCancelacion(original, plan, null);

        // El objeto original no debe haber cambiado
        assertEquals(3, original.getSaldoActual(),
                "La suscripción original es inmutable; devolverPorCancelacion devuelve una nueva instancia");
        assertEquals(4, result.subscription().getSaldoActual());
    }

    // ── Fixtures ────────────────────────────────────────────────────────────

    private UserSubscription subWithSaldo(int saldo, SubscriptionEstado estado, LocalDateTime expira) {
        return new UserSubscription(
                UUID.randomUUID(),
                UUID.randomUUID(),
                UUID.randomUUID(),
                UUID.randomUUID(),
                saldo,
                now.minusDays(30),
                expira,
                estado,
                now.minusDays(30),
                now.minusDays(30)
        );
    }

    private Plan plan(PlanTipo tipo, Integer totalCreditos) {
        return new Plan(
                UUID.randomUUID(),
                UUID.randomUUID(),
                "Plan Test",
                tipo,
                PlanTier.GOLDEN,
                totalCreditos,
                30,
                BigDecimal.valueOf(100),
                true,
                now.minusDays(30),
                now.minusDays(30)
        );
    }
}

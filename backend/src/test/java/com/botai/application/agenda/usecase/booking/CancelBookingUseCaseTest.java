package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BookingNotCancellableException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.CancellationNotAllowedException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.CreditMotivo;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import com.botai.domain.agenda.service.CancellationDomainService;
import com.botai.domain.agenda.service.CreditDomainService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CancelBookingUseCaseTest {

    // ── repos y servicios mockeados ───────────────────────────────────────────
    private BookingRepository bookingRepository;
    private BusinessRepository businessRepository;
    private BusinessSettingsRepository settingsRepository;
    private UserSubscriptionRepository subscriptionRepository;
    private PlanRepository planRepository;
    private CreditTransactionRepository transactionRepository;

    private CancelBookingUseCase useCase;
    private Clock fixedClock;
    private LocalDateTime now;

    // ── ids reutilizables ────────────────────────────────────────────────────
    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID USER_ID = UUID.randomUUID();
    private final UUID BOOKING_ID = UUID.randomUUID();
    private final UUID SUBSCRIPTION_ID = UUID.randomUUID();
    private final UUID PLAN_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        bookingRepository = mock(BookingRepository.class);
        businessRepository = mock(BusinessRepository.class);
        settingsRepository = mock(BusinessSettingsRepository.class);
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        planRepository = mock(PlanRepository.class);
        transactionRepository = mock(CreditTransactionRepository.class);

        now = LocalDateTime.of(2026, 5, 10, 10, 0);
        fixedClock = Clock.fixed(now.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);

        useCase = new CancelBookingUseCase(
                bookingRepository,
                businessRepository,
                settingsRepository,
                subscriptionRepository,
                planRepository,
                transactionRepository,
                new CancellationDomainService(),
                new CreditDomainService(),
                new io.micrometer.core.instrument.simple.SimpleMeterRegistry(),
                fixedClock
        );

        // Defaults: business y settings OK
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        when(settingsRepository.findByBusinessId(BUSINESS_ID))
                .thenReturn(Optional.of(BusinessSettings.defaults(BUSINESS_ID)));
    }

    // ── flujo feliz ──────────────────────────────────────────────────────────

    @Test
    void cancelarConSubscripcion_guardaBookingCanceladoYDevuelveCredito() {
        Booking booking = confirmedBookingWithSub(now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        UserSubscription sub = subscription(5);
        when(subscriptionRepository.findByIdForUpdate(SUBSCRIPTION_ID)).thenReturn(Optional.of(sub));

        Plan plan = plan(PlanTipo.POR_CREDITOS);
        when(planRepository.findById(PLAN_ID)).thenReturn(Optional.of(plan));

        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID);

        // Booking guardado en estado CANCELLED con canceladaAt
        ArgumentCaptor<Booking> bookingCaptor = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(bookingCaptor.capture());
        Booking saved = bookingCaptor.getValue();
        assertEquals(BookingEstado.CANCELLED, saved.getEstado());
        assertEquals(now, saved.getCanceladaAt());

        // Suscripción actualizada con saldo +1
        ArgumentCaptor<UserSubscription> subCaptor = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertEquals(6, subCaptor.getValue().getSaldoActual());

        // CreditTransaction de devolución guardada
        verify(transactionRepository).save(argThat(tx ->
                tx.getMonto() == 1 && tx.getMotivo() == CreditMotivo.CANCELACION_DEVUELTA));
    }

    @Test
    void cancelarSinSubscripcion_guardaBookingCanceladoSinTocarCreditos() {
        Booking booking = confirmedBookingNoSub(now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));
        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID);

        verify(bookingRepository).save(argThat(b -> b.getEstado() == BookingEstado.CANCELLED));
        verify(subscriptionRepository, never()).findByIdForUpdate(any());
        verify(transactionRepository, never()).save(any());
    }

    @Test
    void cancelarPlanIlimitado_guardaTxConMontoZero() {
        Booking booking = confirmedBookingWithSub(now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        UserSubscription sub = subscription(0);
        when(subscriptionRepository.findByIdForUpdate(SUBSCRIPTION_ID)).thenReturn(Optional.of(sub));
        when(planRepository.findById(PLAN_ID)).thenReturn(Optional.of(plan(PlanTipo.ILIMITADO_MENSUAL)));
        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID);

        verify(transactionRepository).save(argThat(tx ->
                tx.getMonto() == 0 && tx.getMotivo() == CreditMotivo.CANCELACION_DEVUELTA));
    }

    // ── validaciones de ownership / tenant ───────────────────────────────────

    @Test
    void businessNoExiste_lanzaBusinessNotFoundException() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
        verify(bookingRepository, never()).findById(any());
    }

    @Test
    void bookingNoExiste_lanzaBookingNotFoundException() {
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.empty());

        assertThrows(BookingNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
    }

    @Test
    void bookingPerteneceAOtroUsuario_lanzaBookingNotFoundException() {
        Booking booking = bookingForUser(UUID.randomUUID(), now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        assertThrows(BookingNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
    }

    @Test
    void bookingPerteneceAOtroNegocio_lanzaBookingNotFoundException() {
        Booking booking = bookingForBusiness(UUID.randomUUID(), now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        assertThrows(BookingNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
    }

    // ── reglas de dominio delegadas ───────────────────────────────────────────

    @Test
    void reservaYaCancelada_lanzaBookingNotCancellableException() {
        Booking booking = bookingWithEstado(BookingEstado.CANCELLED, now.plusHours(6));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        assertThrows(BookingNotCancellableException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
    }

    @Test
    void fueraDeVentana_lanzaCancellationNotAllowedException() {
        // inicio en 2h → ventana de 4h ya cerró
        Booking booking = confirmedBookingWithSub(now.plusHours(2));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));

        assertThrows(CancellationNotAllowedException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID));
    }

    @Test
    void settingsNoConfiguradas_usaDefaultsCon4h() {
        when(settingsRepository.findByBusinessId(BUSINESS_ID)).thenReturn(Optional.empty());
        // Con defaults (4h), reserva en 5h → OK
        Booking booking = confirmedBookingWithSub(now.plusHours(5));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking));
        when(subscriptionRepository.findByIdForUpdate(SUBSCRIPTION_ID))
                .thenReturn(Optional.of(subscription(3)));
        when(planRepository.findById(PLAN_ID)).thenReturn(Optional.of(plan(PlanTipo.POR_CREDITOS)));
        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(TENANT, BUSINESS_ID, USER_ID, BOOKING_ID);

        verify(bookingRepository).save(argThat(b -> b.getEstado() == BookingEstado.CANCELLED));
    }

    // ── fixtures ──────────────────────────────────────────────────────────────

    private Booking confirmedBookingWithSub(LocalDateTime inicio) {
        return new Booking(BOOKING_ID, BUSINESS_ID, UUID.randomUUID(), USER_ID,
                SUBSCRIPTION_ID, null, inicio, inicio.plusHours(1),
                BookingEstado.CONFIRMED, null, null, null, now.minusDays(1), now.minusDays(1));
    }

    private Booking confirmedBookingNoSub(LocalDateTime inicio) {
        return new Booking(BOOKING_ID, BUSINESS_ID, UUID.randomUUID(), USER_ID,
                null, null, inicio, inicio.plusHours(1),
                BookingEstado.CONFIRMED, null, null, null, now.minusDays(1), now.minusDays(1));
    }

    private Booking bookingWithEstado(BookingEstado estado, LocalDateTime inicio) {
        return new Booking(BOOKING_ID, BUSINESS_ID, UUID.randomUUID(), USER_ID,
                SUBSCRIPTION_ID, null, inicio, inicio.plusHours(1),
                estado, null, null, null, now.minusDays(1), now.minusDays(1));
    }

    private Booking bookingForUser(UUID userId, LocalDateTime inicio) {
        return new Booking(BOOKING_ID, BUSINESS_ID, UUID.randomUUID(), userId,
                SUBSCRIPTION_ID, null, inicio, inicio.plusHours(1),
                BookingEstado.CONFIRMED, null, null, null, now.minusDays(1), now.minusDays(1));
    }

    private Booking bookingForBusiness(UUID businessId, LocalDateTime inicio) {
        return new Booking(BOOKING_ID, businessId, UUID.randomUUID(), USER_ID,
                SUBSCRIPTION_ID, null, inicio, inicio.plusHours(1),
                BookingEstado.CONFIRMED, null, null, null, now.minusDays(1), now.minusDays(1));
    }

    private UserSubscription subscription(int saldo) {
        return new UserSubscription(SUBSCRIPTION_ID, USER_ID, PLAN_ID, BUSINESS_ID,
                saldo, now.minusDays(30), now.plusDays(30),
                SubscriptionEstado.ACTIVE, now.minusDays(30), now.minusDays(30));
    }

    private Plan plan(PlanTipo tipo) {
        return new Plan(PLAN_ID, BUSINESS_ID, "Plan Test", tipo, PlanTier.GOLDEN,
                tipo == PlanTipo.POR_CREDITOS || tipo == PlanTipo.MIXTO ? 10 : null,
                30, BigDecimal.valueOf(100), true, now.minusDays(30), now.minusDays(30));
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }
}

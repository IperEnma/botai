package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.exception.BookingSlotTakenException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.NoCreditsException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.exception.SubscriptionExpiredException;
import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.OutboxEventRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import com.botai.domain.agenda.service.BookingDomainService;
import com.botai.domain.agenda.service.CreditDomainService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import io.micrometer.core.instrument.MeterRegistry;
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
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit test del orquestador {@link CreateBookingUseCase}.
 *
 * <p>Cubre happy-path (descuento + booking + tx + evento) y los caminos de
 * error relevantes (business/service/subscription/plan no encontrados,
 * ownership mismatch, saldo agotado, sub vencida, slot tomado).</p>
 *
 * <p>Los servicios de dominio ({@code CreditDomainService},
 * {@code BookingDomainService}) se usan reales: el test igual queda puro porque
 * mockeamos los repositorios que ellos usan.</p>
 */
class CreateBookingUseCaseTest {

    private BusinessRepository businessRepository;
    private ServiceRepository serviceRepository;
    private UserSubscriptionRepository subscriptionRepository;
    private PlanRepository planRepository;
    private BookingRepository bookingRepository;
    private CreditTransactionRepository transactionRepository;
    private OutboxEventRepository outboxEventRepository;
    private StaffMemberRepository staffMemberRepository;
    private Clock clock;

    private CreateBookingUseCase useCase;

    private LocalDateTime now;

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        serviceRepository = mock(ServiceRepository.class);
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        planRepository = mock(PlanRepository.class);
        bookingRepository = mock(BookingRepository.class);
        transactionRepository = mock(CreditTransactionRepository.class);
        outboxEventRepository = mock(OutboxEventRepository.class);
        staffMemberRepository = mock(StaffMemberRepository.class);
        when(outboxEventRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        now = LocalDateTime.of(2026, 4, 20, 10, 0);
        Instant fixedInstant = now.toInstant(ZoneOffset.UTC);
        clock = Clock.fixed(fixedInstant, ZoneOffset.UTC);

        useCase = new CreateBookingUseCase(
                businessRepository,
                serviceRepository,
                subscriptionRepository,
                planRepository,
                bookingRepository,
                transactionRepository,
                new CreditDomainService(),
                new BookingDomainService(bookingRepository),
                outboxEventRepository,
                staffMemberRepository,
                new ObjectMapper().registerModule(new JavaTimeModule()),
                new io.micrometer.core.instrument.simple.SimpleMeterRegistry(),
                clock
        );
    }

    @Test
    void creaBookingHappyPath() {
        String tenantId = "tenant-1";
        UUID businessId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();
        LocalDateTime inicio = now.plusDays(1);

        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(business(businessId, tenantId)));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 3, SubscriptionEstado.ACTIVE, now.plusDays(10))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.POR_CREDITOS, 10)));
        when(bookingRepository.findOverlapping(eq(businessId), eq(serviceId), any(), any()))
                .thenReturn(List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(inv -> {
            Booking b = inv.getArgument(0);
            return new Booking(
                    UUID.randomUUID(), b.getBusinessId(), b.getServiceId(), b.getUserId(),
                    b.getSubscriptionId(), null, b.getFechaHoraInicio(), b.getFechaHoraFin(),
                    b.getEstado(), b.getNotas(), b.getCanceladaAt(), b.getCompletadaAt(),
                    now, now);
        });

        Booking result = useCase.execute(tenantId, businessId, userId, serviceId, subId, null, inicio, "test");

        assertNotNull(result.getId());
        assertEquals(BookingEstado.CONFIRMED, result.getEstado());
        assertEquals(inicio, result.getFechaHoraInicio());
        assertEquals(inicio.plusMinutes(30), result.getFechaHoraFin());

        // El booking se guarda:
        ArgumentCaptor<Booking> bookingCaptor = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(bookingCaptor.capture());
        assertEquals(BookingEstado.CONFIRMED, bookingCaptor.getValue().getEstado());

        // La suscripción persistida tiene saldo-1:
        ArgumentCaptor<UserSubscription> subCaptor = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertEquals(2, subCaptor.getValue().getSaldoActual(),
                "El saldo actualizado persiste con un descuento de 1 crédito");

        // La tx persistida tiene bookingId del booking ya guardado:
        ArgumentCaptor<CreditTransaction> txCaptor = ArgumentCaptor.forClass(CreditTransaction.class);
        verify(transactionRepository).save(txCaptor.capture());
        assertEquals(-1, txCaptor.getValue().getMonto());
        assertEquals(result.getId(), txCaptor.getValue().getBookingId(),
                "La tx se re-construye con el id del booking ya persistido");

        // Evento persistido en outbox (misma tx):
        verify(outboxEventRepository).save(any());
    }

    @Test
    void tiraBusinessNotFoundSiElTenantNoMatch() {
        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class, () -> useCase.execute(
                "t", UUID.randomUUID(), UUID.randomUUID(),
                UUID.randomUUID(), UUID.randomUUID(),
                null, now.plusDays(1), null));

        verify(subscriptionRepository, never()).findByIdForUpdate(any());
    }

    @Test
    void tiraServiceNotFoundSiServicioNoExiste() {
        UUID businessId = UUID.randomUUID();
        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(any())).thenReturn(Optional.empty());

        assertThrows(ServiceNotFoundException.class, () -> useCase.execute(
                "t", businessId, UUID.randomUUID(),
                UUID.randomUUID(), UUID.randomUUID(),
                null, now.plusDays(1), null));
    }

    @Test
    void tiraServiceNotFoundSiElServicioEsDeOtroNegocio() {
        UUID businessId = UUID.randomUUID();
        UUID otroBusiness = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, otroBusiness, 30)));

        assertThrows(ServiceNotFoundException.class, () -> useCase.execute(
                "t", businessId, UUID.randomUUID(),
                serviceId, UUID.randomUUID(),
                null, now.plusDays(1), null));
    }

    @Test
    void tiraSubscriptionNotFoundSiLaSuscripcionEsDeOtroUser() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID otroUser = UUID.randomUUID();
        UUID planId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, otroUser, businessId, planId, 5,
                        SubscriptionEstado.ACTIVE, now.plusDays(10))));

        assertThrows(UserSubscriptionNotFoundException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, null, now.plusDays(1), null));
    }

    @Test
    void tiraSubscriptionNotFoundSiLaSuscripcionEsDeOtroNegocio() {
        UUID businessId = UUID.randomUUID();
        UUID otroBusiness = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, otroBusiness, planId, 5,
                        SubscriptionEstado.ACTIVE, now.plusDays(10))));

        assertThrows(UserSubscriptionNotFoundException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, null, now.plusDays(1), null));
    }

    @Test
    void tiraPlanNotFoundSiElPlanDesapareció() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 5,
                        SubscriptionEstado.ACTIVE, now.plusDays(10))));
        when(planRepository.findById(planId)).thenReturn(Optional.empty());

        assertThrows(PlanNotFoundException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, null, now.plusDays(1), null));
    }

    @Test
    void tiraNoCreditsSiElSaldoEsCero() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 0,
                        SubscriptionEstado.ACTIVE, now.plusDays(10))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.POR_CREDITOS, 10)));

        assertThrows(NoCreditsException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, null, now.plusDays(1), null));

        verify(bookingRepository, never()).save(any());
    }

    @Test
    void tiraSubscriptionExpiredSiLaFechaPasó() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 5,
                        SubscriptionEstado.ACTIVE, now.minusSeconds(1))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.POR_CREDITOS, 10)));

        assertThrows(SubscriptionExpiredException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, null, now.plusDays(1), null));
    }

    @Test
    void tiraSlotTakenSiHayOverlap_yNoGuardaNada() {
        // No-solapamiento por staff a nivel tenant: si el profesional ya
        // tiene una reserva activa que se solapa con el slot pedido (incluso
        // en otra sucursal), la reserva debe rechazarse y nada debe persistir.
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID staffMemberId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();
        LocalDateTime inicio = now.plusDays(1);

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 30)));
        when(staffMemberRepository.findById(staffMemberId))
                .thenReturn(Optional.of(com.botai.domain.agenda.model.StaffMember.builder()
                        .id(staffMemberId)
                        .businessId(businessId)
                        .nombre("Profe")
                        .status("ACTIVO")
                        .build()));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 5,
                        SubscriptionEstado.ACTIVE, now.plusDays(10))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.POR_CREDITOS, 10)));

        Booking colision = new Booking(
                UUID.randomUUID(), businessId, serviceId,
                UUID.randomUUID(), UUID.randomUUID(),
                staffMemberId, inicio, inicio.plusMinutes(30),
                BookingEstado.CONFIRMED, null, null, null, null, null);
        when(bookingRepository.findOverlappingForStaff(eq(staffMemberId), any(), any()))
                .thenReturn(List.of(colision));

        assertThrows(BookingSlotTakenException.class, () -> useCase.execute(
                "t", businessId, userId, serviceId, subId, staffMemberId, inicio, null));

        // Nada se persiste si el slot está ocupado — el crédito se calcula en memoria
        // antes de la validación del slot, pero nunca debe guardarse si falla.
        verify(bookingRepository, never()).save(any());
        verify(subscriptionRepository, never()).save(any());
        verify(transactionRepository, never()).save(any());
        verify(outboxEventRepository, never()).save(any());
    }

    @Test
    void planIlimitadoMensual_noDescuentaSaldoPeroGuardaTxConMontosCero() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();
        LocalDateTime inicio = now.plusDays(1);

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 60)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 0,
                        SubscriptionEstado.ACTIVE, now.plusDays(30))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.ILIMITADO_MENSUAL, null)));
        when(bookingRepository.findOverlapping(any(), any(), any(), any())).thenReturn(List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(inv -> {
            Booking b = inv.getArgument(0);
            return new Booking(UUID.randomUUID(), b.getBusinessId(), b.getServiceId(), b.getUserId(),
                    b.getSubscriptionId(), null, b.getFechaHoraInicio(), b.getFechaHoraFin(),
                    b.getEstado(), b.getNotas(), null, null, now, now);
        });

        useCase.execute("t", businessId, userId, serviceId, subId, null, inicio, null);

        // Saldo no cambia (era 0 y sigue en 0)
        ArgumentCaptor<UserSubscription> subCaptor = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptionRepository).save(subCaptor.capture());
        assertEquals(0, subCaptor.getValue().getSaldoActual(),
                "ILIMITADO_MENSUAL: el saldo no se toca");

        // Tx guardada con monto=0 para trazabilidad
        ArgumentCaptor<CreditTransaction> txCaptor = ArgumentCaptor.forClass(CreditTransaction.class);
        verify(transactionRepository).save(txCaptor.capture());
        assertEquals(0, txCaptor.getValue().getMonto(),
                "ILIMITADO_MENSUAL: la tx existe pero con monto=0");
    }

    @Test
    void planSoloReserva_noDescuentaSaldoNiLoRequiere() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();
        LocalDateTime inicio = now.plusDays(1);

        when(businessRepository.findByIdAndTenantId(any(), any()))
                .thenReturn(Optional.of(business(businessId, "t")));
        when(serviceRepository.findById(serviceId))
                .thenReturn(Optional.of(service(serviceId, businessId, 45)));
        when(subscriptionRepository.findByIdForUpdate(subId))
                .thenReturn(Optional.of(subscription(subId, userId, businessId, planId, 0,
                        SubscriptionEstado.ACTIVE, now.plusDays(15))));
        when(planRepository.findById(planId))
                .thenReturn(Optional.of(plan(planId, businessId, PlanTipo.SOLO_RESERVA, null)));
        when(bookingRepository.findOverlapping(any(), any(), any(), any())).thenReturn(List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(inv -> {
            Booking b = inv.getArgument(0);
            return new Booking(UUID.randomUUID(), b.getBusinessId(), b.getServiceId(), b.getUserId(),
                    b.getSubscriptionId(), null, b.getFechaHoraInicio(), b.getFechaHoraFin(),
                    b.getEstado(), b.getNotas(), null, null, now, now);
        });

        Booking result = useCase.execute("t", businessId, userId, serviceId, subId, null, inicio, null);

        assertEquals(BookingEstado.CONFIRMED, result.getEstado());

        ArgumentCaptor<CreditTransaction> txCaptor = ArgumentCaptor.forClass(CreditTransaction.class);
        verify(transactionRepository).save(txCaptor.capture());
        assertEquals(0, txCaptor.getValue().getMonto(),
                "SOLO_RESERVA: monto=0, no hay descuento real");
    }

    // ── Fixtures ────────────────────────────────────────────────────────────

    private Business business(UUID id, String tenantId) {
        return new Business(id, tenantId, "Test Biz", null,
                UUID.randomUUID(), List.of(), true,
                null, null, null, null, null, null, null, null, now.minusDays(30), now.minusDays(30));
    }

    private Service service(UUID id, UUID businessId, int duracion) {
        return new Service(id, businessId, "Servicio Test", null,
                duracion, BigDecimal.valueOf(500), true,
                com.botai.domain.agenda.model.ServiceSchedulingMode.GENERAL,
                null, now.minusDays(30), now.minusDays(30));
    }

    private UserSubscription subscription(UUID id, UUID userId, UUID businessId, UUID planId,
                                          int saldo, SubscriptionEstado estado,
                                          LocalDateTime fechaExpiracion) {
        return new UserSubscription(id, userId, planId, businessId, saldo,
                now.minusDays(30), fechaExpiracion, estado,
                now.minusDays(30), now.minusDays(30));
    }

    private Plan plan(UUID id, UUID businessId, PlanTipo tipo, Integer totalCreditos) {
        return new Plan(id, businessId, "Plan Test", tipo, PlanTier.GOLDEN,
                totalCreditos, 30, BigDecimal.valueOf(1000), true,
                now.minusDays(30), now.minusDays(30));
    }
}

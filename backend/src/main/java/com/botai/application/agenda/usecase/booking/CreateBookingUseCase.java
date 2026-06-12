package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.event.BookingConfirmedEvent;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.exception.StaffMemberNotFoundException;
import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.OutboxEvent;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.StaffMember;
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
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * CU-01 (parte reserva): crea una reserva confirmada y descuenta crédito de
 * forma atómica.
 *
 * <p>Flujo bajo {@code @Transactional(READ_COMMITTED)}:</p>
 * <ol>
 *   <li>Validar tenant/business/service.</li>
 *   <li>Bloquear la suscripción con {@code findByIdForUpdate} (SELECT ... FOR
 *       UPDATE). Esto serializa los descuentos sobre la misma billetera.</li>
 *   <li>Cargar el plan para conocer el tipo.</li>
 *   <li>Validar vigencia y saldo con {@code CreditDomainService}.</li>
 *   <li>Validar disponibilidad del slot con {@code BookingDomainService}.</li>
 *   <li>Guardar booking, guardar subscription actualizada, guardar
 *       CreditTransaction. Todo en la misma tx.</li>
 *   <li>Publicar {@code BookingConfirmedEvent} (consumido by listeners en
 *       phase AFTER_COMMIT en Slices siguientes).</li>
 * </ol>
 *
 * <p>El orden importa: primero se toma el lock de la suscripción, y recién
 * después se valida el slot. Si dos requests concurrentes quieren reservar
 * distintas sesiones con la misma suscripción, se serializan acá; si quieren
 * distintas suscripciones, no se bloquean entre sí (lo cual está bien — solo
 * compite por suscripción + slot).</p>
 */
@org.springframework.stereotype.Service
public class CreateBookingUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreateBookingUseCase.class);

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final UserSubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;
    private final BookingRepository bookingRepository;
    private final CreditTransactionRepository transactionRepository;
    private final CreditDomainService creditService;
    private final BookingDomainService bookingService;
    private final OutboxEventRepository outboxEventRepository;
    private final StaffMemberRepository staffMemberRepository;
    private final ObjectMapper objectMapper;
    private final MeterRegistry meterRegistry;
    private final Clock clock;

    public CreateBookingUseCase(BusinessRepository businessRepository,
                                ServiceRepository serviceRepository,
                                UserSubscriptionRepository subscriptionRepository,
                                PlanRepository planRepository,
                                BookingRepository bookingRepository,
                                CreditTransactionRepository transactionRepository,
                                CreditDomainService creditService,
                                BookingDomainService bookingService,
                                OutboxEventRepository outboxEventRepository,
                                StaffMemberRepository staffMemberRepository,
                                ObjectMapper objectMapper,
                                MeterRegistry meterRegistry,
                                Clock clock) {
        this.businessRepository    = businessRepository;
        this.serviceRepository     = serviceRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository        = planRepository;
        this.bookingRepository     = bookingRepository;
        this.transactionRepository = transactionRepository;
        this.creditService         = creditService;
        this.bookingService        = bookingService;
        this.outboxEventRepository = outboxEventRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.objectMapper          = objectMapper;
        this.meterRegistry         = meterRegistry;
        this.clock                 = clock;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Booking execute(String tenantId,
                           UUID businessId,
                           UUID userId,
                           UUID serviceId,
                           UUID subscriptionId,
                           UUID staffMemberId,
                           LocalDateTime fechaHoraInicio,
                           String notas) {
        // 1. Validar tenant/business.
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        // 2. Validar servicio y que pertenezca al negocio.
        Service service = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));
        if (!service.getBusinessId().equals(businessId)) {
            // Se expone como "servicio no encontrado" para no revelar cross-business.
            throw new ServiceNotFoundException(serviceId);
        }

        LocalDateTime fechaHoraFin = fechaHoraInicio.plusMinutes(service.getDuracionMin());

        // 3. Validar miembro del equipo si se especificó.
        if (staffMemberId != null) {
            StaffMember staffMember = staffMemberRepository.findById(staffMemberId)
                    .orElseThrow(() -> new StaffMemberNotFoundException(staffMemberId));
            if (!staffMember.isActivo()) {
                throw new IllegalStateException("El miembro de equipo seleccionado no está disponible");
            }
        }

        // 4. Bloquear la suscripción. Todo el resto del flujo corre con esta
        //    fila tomada, así evitamos doble descuento.
        UserSubscription locked = subscriptionRepository.findByIdForUpdate(subscriptionId)
                .orElseThrow(() -> new UserSubscriptionNotFoundException(subscriptionId));
        if (!locked.getUserId().equals(userId)) {
            // Ownership: no exponer suscripciones ajenas.
            throw new UserSubscriptionNotFoundException(subscriptionId);
        }
        if (!locked.getBusinessId().equals(businessId)) {
            // Suscripción de otro negocio: tratamos como no encontrada.
            throw new UserSubscriptionNotFoundException(subscriptionId);
        }

        // 5. Plan (para conocer tipo; ya confiamos en que existe porque FK RESTRICT).
        Plan plan = planRepository.findById(locked.getPlanId())
                .orElseThrow(() -> new PlanNotFoundException(locked.getPlanId()));

        LocalDateTime now = LocalDateTime.now(clock);

        // 6. Descontar crédito (valida vigencia y saldo). Devuelve sub actualizada + tx.
        //    Todavía no tenemos bookingId; generamos el booking después y actualizamos
        //    la tx con el id antes de persistirla.
        CreditDomainService.CreditDebit debit =
                creditService.descontarPorReserva(locked, plan, null, now);

        // 7. Disponibilidad de slot (no-solapamiento global del staff a nivel tenant).
        bookingService.validarDisponibilidad(staffMemberId, fechaHoraInicio, fechaHoraFin);

        // 8. Construir booking CONFIRMED y guardar.
        Booking confirmed = bookingService.construirConfirmada(
                businessId, serviceId, userId, subscriptionId, staffMemberId,
                fechaHoraInicio, fechaHoraFin, notas);
        Booking savedBooking = bookingRepository.save(confirmed);

        // 9. Persistir subscription actualizada y la transacción (ya con bookingId).
        subscriptionRepository.save(debit.subscription());
        transactionRepository.save(new com.botai.domain.agenda.model.CreditTransaction(
                null,
                debit.transaction().getSubscriptionId(),
                debit.transaction().getMonto(),
                debit.transaction().getMotivo(),
                savedBooking.getId(),
                null
        ));

        // 10. Persistir evento en outbox (misma tx) — el scheduler lo publica luego.
        try {
            String payload = objectMapper.writeValueAsString(new BookingConfirmedEvent(
                    savedBooking.getId(), businessId, userId, subscriptionId, fechaHoraInicio));
            outboxEventRepository.save(new OutboxEvent(
                    null, BookingConfirmedEvent.class.getSimpleName(),
                    payload, OutboxEvent.STATUS_PENDING, null, null));
        } catch (Exception ex) {
            log.error("AGENDA: error serializando outbox event para booking={}", savedBooking.getId(), ex);
        }

        meterRegistry.counter("agenda.bookings.created").increment();
        log.info("AGENDA: booking confirmado id={} user={} sub={} slot={}",
                savedBooking.getId(), userId, subscriptionId, fechaHoraInicio);
        return savedBooking;
    }
}

package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import com.botai.domain.agenda.service.CancellationDomainService;
import com.botai.domain.agenda.service.CreditDomainService;
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * CU-01 (parte cancelación): cancela una reserva del usuario y, si corresponde,
 * devuelve el crédito a la suscripción.
 *
 * <p>Flujo bajo {@code @Transactional(READ_COMMITTED)}:</p>
 * <ol>
 *   <li>Cargar y validar que la reserva pertenezca al tenant/business/usuario.</li>
 *   <li>Cargar la configuración del negocio para obtener la ventana de cancelación.</li>
 *   <li>Delegar en {@link CancellationDomainService} la validación del estado y
 *       la ventana temporal; obtener el booking cancelado.</li>
 *   <li>Si la reserva tenía suscripción asociada: bloquear la suscripción
 *       ({@code SELECT ... FOR UPDATE}), obtener el plan, invocar
 *       {@link CreditDomainService#devolverPorCancelacion} y persistir la
 *       suscripción actualizada + la {@code CreditTransaction}.</li>
 *   <li>Persistir el booking cancelado.</li>
 * </ol>
 */
@Service
public class CancelBookingUseCase {

    private static final Logger log = LoggerFactory.getLogger(CancelBookingUseCase.class);

    private final BookingRepository bookingRepository;
    private final BusinessRepository businessRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final UserSubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;
    private final CreditTransactionRepository transactionRepository;
    private final CancellationDomainService cancellationService;
    private final CreditDomainService creditService;
    private final MeterRegistry meterRegistry;
    private final Clock clock;

    public CancelBookingUseCase(BookingRepository bookingRepository,
                                BusinessRepository businessRepository,
                                BusinessSettingsRepository settingsRepository,
                                UserSubscriptionRepository subscriptionRepository,
                                PlanRepository planRepository,
                                CreditTransactionRepository transactionRepository,
                                CancellationDomainService cancellationService,
                                CreditDomainService creditService,
                                MeterRegistry meterRegistry,
                                Clock clock) {
        this.bookingRepository  = bookingRepository;
        this.businessRepository = businessRepository;
        this.settingsRepository = settingsRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository     = planRepository;
        this.transactionRepository = transactionRepository;
        this.cancellationService = cancellationService;
        this.creditService      = creditService;
        this.meterRegistry      = meterRegistry;
        this.clock              = clock;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public void execute(String tenantId, UUID businessId, UUID userId, UUID bookingId) {
        // 1. Validar que el business existe y pertenece al tenant.
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        // 2. Cargar la reserva y validar ownership.
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new BookingNotFoundException(bookingId));

        if (!booking.getUserId().equals(userId)) {
            // No revelar reservas ajenas; tratar como no encontrada.
            throw new BookingNotFoundException(bookingId);
        }
        if (!booking.getBusinessId().equals(businessId)) {
            throw new BookingNotFoundException(bookingId);
        }

        // 3. Configuración del negocio para la ventana de cancelación.
        BusinessSettings settings = settingsRepository.findByBusinessId(businessId)
                .orElseGet(() -> BusinessSettings.defaults(businessId));

        LocalDateTime now = LocalDateTime.now(clock);

        // 4. Validar estado + ventana y construir booking cancelado.
        Booking cancelled = cancellationService.cancelar(booking, settings, now);

        // 5. Si había suscripción, devolver crédito (con lock para serializar).
        if (booking.getSubscriptionId() != null) {
            UserSubscription locked = subscriptionRepository
                    .findByIdForUpdate(booking.getSubscriptionId())
                    .orElseThrow(() -> new UserSubscriptionNotFoundException(
                            booking.getSubscriptionId()));

            Plan plan = planRepository.findById(locked.getPlanId())
                    .orElseThrow(() -> new com.botai.domain.agenda.exception.PlanNotFoundException(
                            locked.getPlanId()));

            CreditDomainService.CreditDebit refund =
                    creditService.devolverPorCancelacion(locked, plan, bookingId);

            subscriptionRepository.save(refund.subscription());
            transactionRepository.save(new CreditTransaction(
                    null,
                    refund.transaction().getSubscriptionId(),
                    refund.transaction().getMonto(),
                    refund.transaction().getMotivo(),
                    bookingId,
                    null
            ));
        }

        // 6. Persistir la reserva cancelada.
        bookingRepository.save(cancelled);

        meterRegistry.counter("agenda.bookings.cancelled").increment();
        log.info("AGENDA: booking cancelado id={} user={} business={} slot={}",
                bookingId, userId, businessId, booking.getFechaHoraInicio());
    }
}

package com.botai.agenda.infrastructure.event;

import com.botai.agenda.domain.event.BookingConfirmedEvent;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.domain.repository.BookingRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import com.botai.agenda.domain.repository.LoyaltySuggestionRepository;
import com.botai.agenda.domain.service.LoyaltyDomainService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.Clock;
import java.time.LocalDateTime;

/**
 * Escucha {@link BookingConfirmedEvent} <b>después del commit</b> de la
 * transacción que creó la reserva, para que el conteo de asistencias sea
 * consistente (la booking ya está visible en la base de datos).
 *
 * <p>Corre en su propia transacción ({@code REQUIRES_NEW}) para no mezclar
 * el resultado del motor de loyalty con la reserva original.</p>
 *
 * <p>Lógica:</p>
 * <ol>
 *   <li>Obtener la configuración del negocio (o defaults si no existe).</li>
 *   <li>Contar bookings CONFIRMED/COMPLETED del usuario en la ventana
 *       {@code loyaltyWindowDays} del negocio.</li>
 *   <li>Si se supera el umbral y no hay ya una sugerencia PENDING para el
 *       par (business, user), crear y persistir una nueva.</li>
 * </ol>
 */
@Component
public class BookingConfirmedEventListener {

    private static final Logger log = LoggerFactory.getLogger(BookingConfirmedEventListener.class);

    private final BookingRepository bookingRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final LoyaltySuggestionRepository suggestionRepository;
    private final LoyaltyDomainService loyaltyService;
    private final Clock clock;

    public BookingConfirmedEventListener(BookingRepository bookingRepository,
                                         BusinessSettingsRepository settingsRepository,
                                         LoyaltySuggestionRepository suggestionRepository,
                                         LoyaltyDomainService loyaltyService,
                                         Clock clock) {
        this.bookingRepository = bookingRepository;
        this.settingsRepository = settingsRepository;
        this.suggestionRepository = suggestionRepository;
        this.loyaltyService = loyaltyService;
        this.clock = clock;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onBookingConfirmed(BookingConfirmedEvent event) {
        BusinessSettings settings = settingsRepository.findByBusinessId(event.businessId())
                .orElseGet(() -> BusinessSettings.defaults(event.businessId()));

        LocalDateTime windowStart = LocalDateTime.now(clock)
                .minusDays(settings.getLoyaltyWindowDays());

        int asistencias = bookingRepository.countConfirmedInWindow(
                event.userId(), event.businessId(), windowStart);

        if (!loyaltyService.debeGenerarSugerencia(asistencias, settings)) {
            return;
        }

        boolean yaExistePendiente = suggestionRepository
                .findPendingByBusinessIdAndUserId(event.businessId(), event.userId())
                .isPresent();

        if (yaExistePendiente) {
            log.debug("AGENDA loyalty: sugerencia PENDING ya existe para user={} biz={}",
                    event.userId(), event.businessId());
            return;
        }

        LoyaltySuggestion suggestion = loyaltyService.crearSugerencia(
                event.businessId(), event.userId());
        suggestionRepository.save(suggestion);

        log.info("AGENDA loyalty: sugerencia creada user={} biz={} asistencias={}",
                event.userId(), event.businessId(), asistencias);
    }
}

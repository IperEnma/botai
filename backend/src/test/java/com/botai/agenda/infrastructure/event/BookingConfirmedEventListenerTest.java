package com.botai.agenda.infrastructure.event;

import com.botai.agenda.domain.event.BookingConfirmedEvent;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import com.botai.agenda.domain.repository.BookingRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import com.botai.agenda.domain.repository.LoyaltySuggestionRepository;
import com.botai.agenda.domain.service.LoyaltyDomainService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class BookingConfirmedEventListenerTest {

    private BookingRepository bookingRepository;
    private BusinessSettingsRepository settingsRepository;
    private LoyaltySuggestionRepository suggestionRepository;
    private BookingConfirmedEventListener listener;

    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID USER_ID = UUID.randomUUID();
    private final UUID BOOKING_ID = UUID.randomUUID();
    private final LocalDateTime NOW = LocalDateTime.of(2026, 5, 10, 9, 0);

    @BeforeEach
    void setUp() {
        bookingRepository = mock(BookingRepository.class);
        settingsRepository = mock(BusinessSettingsRepository.class);
        suggestionRepository = mock(LoyaltySuggestionRepository.class);

        Clock fixedClock = Clock.fixed(NOW.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);

        listener = new BookingConfirmedEventListener(
                bookingRepository,
                settingsRepository,
                suggestionRepository,
                new LoyaltyDomainService(),
                fixedClock
        );

        // Default: settings con umbral 3, ventana 30 días
        when(settingsRepository.findByBusinessId(BUSINESS_ID))
                .thenReturn(Optional.of(BusinessSettings.defaults(BUSINESS_ID)));
    }

    // ── genera sugerencia ──────────────────────────────────────────────────────

    @Test
    void asistenciasIgualesAlUmbral_creaSugerencia() {
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(3);
        when(suggestionRepository.findPendingByBusinessIdAndUserId(BUSINESS_ID, USER_ID))
                .thenReturn(Optional.empty());
        when(suggestionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        listener.onBookingConfirmed(event());

        verify(suggestionRepository).save(argThat(s ->
                s.getEstado() == LoyaltySuggestionEstado.PENDING
                        && s.getBusinessId().equals(BUSINESS_ID)
                        && s.getUserId().equals(USER_ID)));
    }

    @Test
    void asistenciasSuperiorAlUmbral_creaSugerencia() {
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(7);
        when(suggestionRepository.findPendingByBusinessIdAndUserId(BUSINESS_ID, USER_ID))
                .thenReturn(Optional.empty());
        when(suggestionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        listener.onBookingConfirmed(event());

        verify(suggestionRepository).save(any());
    }

    // ── no genera sugerencia ──────────────────────────────────────────────────

    @Test
    void asistenciasBajoUmbral_noCreaSugerencia() {
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(2);

        listener.onBookingConfirmed(event());

        verify(suggestionRepository, never()).save(any());
    }

    @Test
    void yaExisteSugerenciaPending_noCreaDuplicado() {
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(5);
        LoyaltySuggestion existente = new LoyaltySuggestion(
                UUID.randomUUID(), BUSINESS_ID, USER_ID,
                LoyaltyDomainService.TRIGGER_THRESHOLD,
                LoyaltySuggestionEstado.PENDING, NOW, NOW);
        when(suggestionRepository.findPendingByBusinessIdAndUserId(BUSINESS_ID, USER_ID))
                .thenReturn(Optional.of(existente));

        listener.onBookingConfirmed(event());

        verify(suggestionRepository, never()).save(any());
    }

    // ── usa defaults cuando no hay settings ───────────────────────────────────

    @Test
    void sinSettings_usaDefaults_conUmbral3() {
        when(settingsRepository.findByBusinessId(BUSINESS_ID)).thenReturn(Optional.empty());
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(3);
        when(suggestionRepository.findPendingByBusinessIdAndUserId(BUSINESS_ID, USER_ID))
                .thenReturn(Optional.empty());
        when(suggestionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        listener.onBookingConfirmed(event());

        verify(suggestionRepository).save(any());
    }

    @Test
    void ventanaCalculadaCorrecta_usaLoyaltyWindowDays() {
        // Defaults: loyaltyWindowDays = 30 → windowStart = NOW - 30 días
        when(bookingRepository.countConfirmedInWindow(any(), any(), any())).thenReturn(2);

        listener.onBookingConfirmed(event());

        LocalDateTime expectedWindow = NOW.minusDays(30);
        verify(bookingRepository).countConfirmedInWindow(USER_ID, BUSINESS_ID, expectedWindow);
    }

    // ── fixture ───────────────────────────────────────────────────────────────

    private BookingConfirmedEvent event() {
        return new BookingConfirmedEvent(BOOKING_ID, BUSINESS_ID, USER_ID,
                UUID.randomUUID(), NOW.plusHours(2));
    }
}

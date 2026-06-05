package com.botai.domain.agenda.service;

import com.botai.domain.agenda.exception.BookingNotCancellableException;
import com.botai.domain.agenda.exception.CancellationNotAllowedException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.BusinessSettings;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CancellationDomainServiceTest {

    private CancellationDomainService service;
    private LocalDateTime now;
    private BusinessSettings settings; // hoursCancellationLimit = 4

    @BeforeEach
    void setUp() {
        service = new CancellationDomainService();
        now = LocalDateTime.of(2026, 5, 10, 10, 0);
        settings = BusinessSettings.defaults(UUID.randomUUID()); // 4h
    }

    // ── estado ────────────────────────────────────────────────────────────────

    @Test
    void cancelarReservaCONFIRMED_devuelveBookingCancelado() {
        Booking booking = booking(BookingEstado.CONFIRMED, now.plusHours(6));

        Booking result = service.cancelar(booking, settings, now);

        assertEquals(BookingEstado.CANCELLED, result.getEstado());
        assertEquals(now, result.getCanceladaAt());
        assertEquals(booking.getId(), result.getId());
    }

    @Test
    void cancelarReservaPENDING_devuelveBookingCancelado() {
        Booking booking = booking(BookingEstado.PENDING, now.plusHours(5));

        Booking result = service.cancelar(booking, settings, now);

        assertEquals(BookingEstado.CANCELLED, result.getEstado());
    }

    @Test
    void cancelarReservaYaCancelada_lanzaBookingNotCancellable() {
        Booking booking = booking(BookingEstado.CANCELLED, now.plusHours(6));

        assertThrows(BookingNotCancellableException.class,
                () -> service.cancelar(booking, settings, now));
    }

    @Test
    void cancelarReservaCOMPLETED_lanzaBookingNotCancellable() {
        Booking booking = booking(BookingEstado.COMPLETED, now.plusHours(6));

        assertThrows(BookingNotCancellableException.class,
                () -> service.cancelar(booking, settings, now));
    }

    @Test
    void cancelarReservaNO_SHOW_lanzaBookingNotCancellable() {
        Booking booking = booking(BookingEstado.NO_SHOW, now.plusHours(6));

        assertThrows(BookingNotCancellableException.class,
                () -> service.cancelar(booking, settings, now));
    }

    // ── ventana temporal ──────────────────────────────────────────────────────

    @Test
    void cancelarJustoDentroDeVentana_ok() {
        // inicio en 4h + 1 segundo → está DENTRO de la ventana libre
        LocalDateTime inicio = now.plusHours(4).plusSeconds(1);
        Booking booking = booking(BookingEstado.CONFIRMED, inicio);

        Booking result = service.cancelar(booking, settings, now);

        assertEquals(BookingEstado.CANCELLED, result.getEstado());
    }

    @Test
    void cancelarExactamenteEnDeadline_lanzaCancellationNotAllowed() {
        // inicio exactamente en 4h: now + 4h → deadline = inicio - 4h = now → NOT before now
        LocalDateTime inicio = now.plusHours(4);
        Booking booking = booking(BookingEstado.CONFIRMED, inicio);

        assertThrows(CancellationNotAllowedException.class,
                () -> service.cancelar(booking, settings, now));
    }

    @Test
    void cancelarFueraDeVentana_lanzaCancellationNotAllowed() {
        // inicio en 2h → deadline fue hace 2h
        Booking booking = booking(BookingEstado.CONFIRMED, now.plusHours(2));

        assertThrows(CancellationNotAllowedException.class,
                () -> service.cancelar(booking, settings, now));
    }

    @Test
    void cancelarReservaEnElPasado_lanzaCancellationNotAllowed() {
        Booking booking = booking(BookingEstado.CONFIRMED, now.minusHours(1));

        assertThrows(CancellationNotAllowedException.class,
                () -> service.cancelar(booking, settings, now));
    }

    // ── inmutabilidad ─────────────────────────────────────────────────────────

    @Test
    void cancelar_preservaInmutabilidadDelOriginal() {
        Booking original = booking(BookingEstado.CONFIRMED, now.plusHours(6));

        service.cancelar(original, settings, now);

        assertEquals(BookingEstado.CONFIRMED, original.getEstado(),
                "El booking original no debe mutar");
    }

    @Test
    void cancelar_preservaCamposNoRelacionados() {
        Booking original = booking(BookingEstado.CONFIRMED, now.plusHours(6));

        Booking result = service.cancelar(original, settings, now);

        assertEquals(original.getBusinessId(), result.getBusinessId());
        assertEquals(original.getServiceId(), result.getServiceId());
        assertEquals(original.getUserId(), result.getUserId());
        assertEquals(original.getSubscriptionId(), result.getSubscriptionId());
        assertEquals(original.getNotas(), result.getNotas());
        assertNotNull(result.getCanceladaAt());
    }

    // ── ventana configurable ──────────────────────────────────────────────────

    @Test
    void ventanaDe24h_cancelarConMenos12h_lanzaExcepcion() {
        BusinessSettings settings24 = new BusinessSettings(
                UUID.randomUUID(), 24, 3, 30, 7, 2, true, true);
        Booking booking = booking(BookingEstado.CONFIRMED, now.plusHours(12));

        assertThrows(CancellationNotAllowedException.class,
                () -> service.cancelar(booking, settings24, now));
    }

    @Test
    void ventanaDe24h_cancelarCon25h_ok() {
        BusinessSettings settings24 = new BusinessSettings(
                UUID.randomUUID(), 24, 3, 30, 7, 2, true, true);
        Booking booking = booking(BookingEstado.CONFIRMED, now.plusHours(25));

        Booking result = service.cancelar(booking, settings24, now);

        assertEquals(BookingEstado.CANCELLED, result.getEstado());
    }

    // ── fixture ───────────────────────────────────────────────────────────────

    private Booking booking(BookingEstado estado, LocalDateTime inicio) {
        LocalDateTime fin = inicio.plusHours(1);
        return new Booking(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
                UUID.randomUUID(), UUID.randomUUID(),
                null,
                inicio, fin, estado, "notas test",
                null, null,
                now.minusDays(1), now.minusDays(1)
        );
    }
}

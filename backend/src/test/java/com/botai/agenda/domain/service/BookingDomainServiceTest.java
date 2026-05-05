package com.botai.agenda.domain.service;

import com.botai.agenda.domain.exception.BookingSlotTakenException;
import com.botai.agenda.domain.model.Booking;
import com.botai.agenda.domain.model.BookingEstado;
import com.botai.agenda.domain.repository.BookingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests unitarios de {@link BookingDomainService}. Sin Spring.
 */
class BookingDomainServiceTest {

    private BookingRepository bookingRepository;
    private BookingDomainService service;

    @BeforeEach
    void setUp() {
        bookingRepository = mock(BookingRepository.class);
        service = new BookingDomainService(bookingRepository);
    }

    // ── validarDisponibilidad ───────────────────────────────────────────────

    @Test
    void validarDisponibilidadOkCuandoNoHayOverlap() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        LocalDateTime desde = LocalDateTime.of(2026, 4, 20, 10, 0);
        LocalDateTime hasta = desde.plusMinutes(30);

        when(bookingRepository.findOverlapping(eq(businessId), eq(serviceId), any(), any()))
                .thenReturn(List.of());

        // No debe tirar:
        service.validarDisponibilidad(businessId, serviceId, desde, hasta);

        verify(bookingRepository).findOverlapping(businessId, serviceId, desde, hasta);
    }

    @Test
    void validarDisponibilidadTiraCuandoHayOverlap() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        LocalDateTime desde = LocalDateTime.of(2026, 4, 20, 10, 0);
        LocalDateTime hasta = desde.plusMinutes(30);

        Booking existente = new Booking(
                UUID.randomUUID(), businessId, serviceId,
                UUID.randomUUID(), UUID.randomUUID(),
                null, desde.minusMinutes(10), hasta.minusMinutes(10),
                BookingEstado.CONFIRMED, null,
                null, null, null, null);

        when(bookingRepository.findOverlapping(any(), any(), any(), any()))
                .thenReturn(List.of(existente));

        assertThrows(BookingSlotTakenException.class,
                () -> service.validarDisponibilidad(businessId, serviceId, desde, hasta));
    }

    // ── construirConfirmada ─────────────────────────────────────────────────

    @Test
    void construirConfirmadaDevuelveBookingConEstadoConfirmedYFechaFin() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID subId = UUID.randomUUID();
        LocalDateTime desde = LocalDateTime.of(2026, 4, 20, 10, 0);
        LocalDateTime hasta = desde.plusMinutes(45);

        Booking booking = service.construirConfirmada(
                businessId, serviceId, userId, subId, null, desde, hasta, "notas test");

        assertNull(booking.getId(), "El id viene null: lo asigna el repo");
        assertEquals(businessId, booking.getBusinessId());
        assertEquals(serviceId, booking.getServiceId());
        assertEquals(userId, booking.getUserId());
        assertEquals(subId, booking.getSubscriptionId());
        assertEquals(desde, booking.getFechaHoraInicio());
        assertEquals(hasta, booking.getFechaHoraFin());
        assertEquals(BookingEstado.CONFIRMED, booking.getEstado());
        assertEquals("notas test", booking.getNotas());
        assertNull(booking.getCanceladaAt());
        assertNull(booking.getCompletadaAt());
    }

    @Test
    void construirConfirmadaAceptaNotasNull() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        LocalDateTime desde = LocalDateTime.of(2026, 4, 20, 10, 0);
        LocalDateTime hasta = desde.plusMinutes(30);

        Booking booking = service.construirConfirmada(
                businessId, serviceId, UUID.randomUUID(), UUID.randomUUID(),
                null, desde, hasta, null);

        assertNotNull(booking);
        assertNull(booking.getNotas());
    }

    @Test
    void construirConfirmadaFallaSiFechaFinEsAntesQueInicio() {
        UUID businessId = UUID.randomUUID();
        UUID serviceId = UUID.randomUUID();
        LocalDateTime desde = LocalDateTime.of(2026, 4, 20, 10, 0);
        // La invariante la chequea el constructor de Booking, pero igual la
        // verificamos acá porque es lo que ve el caller del service.
        assertThrows(IllegalArgumentException.class, () ->
                service.construirConfirmada(
                        businessId, serviceId,
                        UUID.randomUUID(), UUID.randomUUID(),
                        null, desde, desde.minusMinutes(1), null));
    }
}

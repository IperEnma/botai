package com.botai.application.agenda.usecase.booking;

import com.botai.application.agenda.support.BookingConfirmedOutboxService;
import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ConfirmBookingUseCaseTest {

    private BusinessRepository businessRepository;
    private BookingRepository bookingRepository;
    private BookingConfirmedOutboxService confirmedOutbox;
    private ConfirmBookingUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID BOOKING_ID = UUID.randomUUID();
    private final UUID USER_ID = UUID.randomUUID();
    private final UUID SERVICE_ID = UUID.randomUUID();
    private final LocalDateTime START = LocalDateTime.of(2026, 5, 24, 10, 0);
    private final LocalDateTime END = START.plusHours(1);

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        bookingRepository = mock(BookingRepository.class);
        confirmedOutbox = mock(BookingConfirmedOutboxService.class);
        useCase = new ConfirmBookingUseCase(businessRepository, bookingRepository, confirmedOutbox);
    }

    @Test
    void confirmarReservaPendiente_devuelveConfirmadaYEncolaEvento() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        Booking pending = booking(BookingEstado.PENDING);
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(pending));
        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Booking result = useCase.execute(TENANT, BUSINESS_ID, BOOKING_ID);

        assertEquals(BookingEstado.CONFIRMED, result.getEstado());
        verify(confirmedOutbox).enqueue(result);
    }

    @Test
    void negocioNoEncontrado_lanzaExcepcion() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, BOOKING_ID));
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void reservaNoPerteneceAlNegocio_lanzaExcepcion() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        UUID otherBusiness = UUID.randomUUID();
        when(bookingRepository.findById(BOOKING_ID))
                .thenReturn(Optional.of(new Booking(
                        BOOKING_ID, otherBusiness, SERVICE_ID, USER_ID, null, null,
                        START, END, BookingEstado.PENDING, null, null, null, START, START)));

        assertThrows(BookingNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, BOOKING_ID));
    }

    @Test
    void reservaYaConfirmada_esIdempotente() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        Booking confirmed = booking(BookingEstado.CONFIRMED);
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(confirmed));

        Booking result = useCase.execute(TENANT, BUSINESS_ID, BOOKING_ID);

        assertEquals(BookingEstado.CONFIRMED, result.getEstado());
        verify(bookingRepository, never()).save(any());
        verify(confirmedOutbox, never()).enqueue(any());
    }

    @Test
    void guardarPersisteEstadoConfirmado() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        when(bookingRepository.findById(BOOKING_ID)).thenReturn(Optional.of(booking(BookingEstado.PENDING)));
        when(bookingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(TENANT, BUSINESS_ID, BOOKING_ID);

        ArgumentCaptor<Booking> captor = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(captor.capture());
        assertEquals(BookingEstado.CONFIRMED, captor.getValue().getEstado());
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }

    private Booking booking(BookingEstado estado) {
        return new Booking(
                BOOKING_ID, BUSINESS_ID, SERVICE_ID, USER_ID, null, null,
                START, END, estado, null, null, null, START, START);
    }
}

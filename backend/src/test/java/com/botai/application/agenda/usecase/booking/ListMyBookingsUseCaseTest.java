package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListMyBookingsUseCaseTest {

    private BookingRepository bookingRepository;
    private BusinessRepository businessRepository;
    private ListMyBookingsUseCase useCase;

    private final String tenantId = "tenant-1";
    private final UUID businessId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        bookingRepository = mock(BookingRepository.class);
        businessRepository = mock(BusinessRepository.class);
        useCase = new ListMyBookingsUseCase(bookingRepository, businessRepository);
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(new Business(
                        businessId, tenantId, "Negocio", null, null,
                        List.of(), true, null, null, null, null, null, null, null, null, null, null)));
    }

    private Booking booking(BookingEstado estado) {
        return new Booking(UUID.randomUUID(), businessId, UUID.randomUUID(), userId,
                UUID.randomUUID(),
                null,
                LocalDateTime.now().plusDays(1), LocalDateTime.now().plusDays(1).plusHours(1),
                estado, null, null, null, null, null);
    }

    @Test
    void sinFiltroDevuelveTodas() {
        List<Booking> all = List.of(booking(BookingEstado.CONFIRMED), booking(BookingEstado.CANCELLED));
        when(bookingRepository.findAllByUserId(userId)).thenReturn(all);

        List<Booking> result = useCase.execute(tenantId, businessId, userId, null);

        assertEquals(2, result.size());
        verify(bookingRepository).findAllByUserId(userId);
    }

    @Test
    void conFiltroEstadoUsaQueryFiltrada() {
        List<Booking> confirmed = List.of(booking(BookingEstado.CONFIRMED));
        when(bookingRepository.findAllByUserIdAndEstado(userId, BookingEstado.CONFIRMED))
                .thenReturn(confirmed);

        List<Booking> result = useCase.execute(tenantId, businessId, userId, BookingEstado.CONFIRMED);

        assertEquals(1, result.size());
        verify(bookingRepository).findAllByUserIdAndEstado(userId, BookingEstado.CONFIRMED);
    }

    @Test
    void lanza404SiNegocioNoExiste() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, userId, null));
    }
}

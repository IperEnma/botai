package com.botai.application.agenda.usecase.review;

import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.domain.agenda.exception.AgendaUnauthorizedException;
import com.botai.domain.agenda.exception.BookingNotCompletedException;
import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ReviewAlreadyExistsException;
import com.botai.domain.agenda.exception.ReviewNotAllowedException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Review;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ReviewRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CreateReviewUseCaseTest {

    private BusinessRepository businessRepository;
    private BookingRepository bookingRepository;
    private ReviewRepository reviewRepository;
    private AgendaPublicClientSessionService sessionService;
    private CreateReviewUseCase useCase;

    private final String tenantId = "tenant-99";
    private final UUID businessId = UUID.randomUUID();
    private final UUID bookingId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();
    private final UUID staffMemberId = UUID.randomUUID();
    private final String token = "valid-token";
    private final String clientIp = "192.168.0.1";

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        bookingRepository = mock(BookingRepository.class);
        reviewRepository = mock(ReviewRepository.class);
        sessionService = mock(AgendaPublicClientSessionService.class);
        useCase = new CreateReviewUseCase(businessRepository, bookingRepository, reviewRepository, sessionService);
    }

    private Business stubBusiness() {
        return new Business(
                businessId, tenantId, "Peluquería Test", "Desc",
                null, List.of(), true, null, null, null, null, null, null, null,
                null, null, null
        );
    }

    private AgendaPublicClientSessionService.ClientSession stubSession() {
        return new AgendaPublicClientSessionService.ClientSession(
                tenantId, userId, "+5491100000000", System.currentTimeMillis() + 60000L
        );
    }

    private Booking stubBooking(BookingEstado estado) {
        LocalDateTime inicio = LocalDateTime.of(2026, 5, 1, 10, 0);
        LocalDateTime fin = inicio.plusHours(1);
        return new Booking(
                bookingId, businessId, UUID.randomUUID(), userId,
                null, staffMemberId, inicio, fin, estado,
                null, null, null, null, null
        );
    }

    private Review stubSavedReview() {
        return new Review(
                UUID.randomUUID(), businessId, bookingId, userId, staffMemberId, 5, "Excelente", LocalDateTime.now()
        );
    }

    @Test
    void happyPath_creaReseña() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(stubSession());
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(stubBooking(BookingEstado.COMPLETED)));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);
        when(reviewRepository.save(any())).thenReturn(stubSavedReview());

        Review result = useCase.execute(businessId, bookingId, 5, "Excelente", token, clientIp);

        assertNotNull(result);
        assertEquals(5, result.getRating());
        verify(reviewRepository).save(any());
        verify(sessionService).recordSessionUsed(token, tenantId, clientIp, "create_review");
    }

    @Test
    void negocioInexistente_lanza404() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void sesionInvalida_lanza401() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp))
                .thenThrow(new IllegalArgumentException("Sesión inválida o expirada."));

        assertThrows(AgendaUnauthorizedException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void bookingDeOtroCliente_lanza403() {
        UUID otroUsuario = UUID.randomUUID();
        AgendaPublicClientSessionService.ClientSession session =
                new AgendaPublicClientSessionService.ClientSession(tenantId, otroUsuario, "+5491100000001", System.currentTimeMillis() + 60000L);

        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(session);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(stubBooking(BookingEstado.COMPLETED)));

        assertThrows(ReviewNotAllowedException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void bookingNoCompletado_lanza422() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(stubSession());
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(stubBooking(BookingEstado.CONFIRMED)));

        assertThrows(BookingNotCompletedException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void reseñaDuplicada_lanza409() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(stubSession());
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(stubBooking(BookingEstado.COMPLETED)));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(true);

        assertThrows(ReviewAlreadyExistsException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void ratingFueraDeRango_lanzaIllegalArgument() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(stubSession());
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(stubBooking(BookingEstado.COMPLETED)));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);

        assertThrows(IllegalArgumentException.class, () ->
                useCase.execute(businessId, bookingId, 6, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }

    @Test
    void bookingNoEncontrado_lanza404() {
        when(businessRepository.findById(businessId)).thenReturn(Optional.of(stubBusiness()));
        when(sessionService.requireSessionForTenant(token, tenantId, clientIp)).thenReturn(stubSession());
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.empty());

        assertThrows(BookingNotFoundException.class, () ->
                useCase.execute(businessId, bookingId, 5, null, token, clientIp));

        verify(reviewRepository, never()).save(any());
    }
}

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
import com.botai.domain.agenda.model.Review;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ReviewRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Crea una reseña de un cliente tras una reserva COMPLETADA.
 * El {@code staffMemberId} se deriva del booking, no del request.
 */
@Service
public class CreateReviewUseCase {

    private static final Logger log = LoggerFactory.getLogger(CreateReviewUseCase.class);

    private final BusinessRepository businessRepository;
    private final BookingRepository bookingRepository;
    private final ReviewRepository reviewRepository;
    private final AgendaPublicClientSessionService sessionService;

    public CreateReviewUseCase(BusinessRepository businessRepository,
                               BookingRepository bookingRepository,
                               ReviewRepository reviewRepository,
                               AgendaPublicClientSessionService sessionService) {
        this.businessRepository = businessRepository;
        this.bookingRepository = bookingRepository;
        this.reviewRepository = reviewRepository;
        this.sessionService = sessionService;
    }

    @Transactional
    public Review execute(UUID businessId,
                          UUID bookingId,
                          int rating,
                          String comentario,
                          String sessionToken,
                          String clientIp) {

        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        AgendaPublicClientSessionService.ClientSession session;
        try {
            session = sessionService.requireSessionForTenant(sessionToken, tenantId, clientIp);
        } catch (IllegalArgumentException e) {
            throw new AgendaUnauthorizedException(e.getMessage());
        }

        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new BookingNotFoundException(bookingId));

        if (!booking.getBusinessId().equals(businessId)) {
            throw new ReviewNotAllowedException("La reserva no pertenece al negocio indicado");
        }

        if (!booking.getUserId().equals(session.userId())) {
            throw new ReviewNotAllowedException("La reserva no pertenece al cliente de la sesión");
        }

        if (booking.getEstado() != BookingEstado.COMPLETED) {
            throw new BookingNotCompletedException(bookingId);
        }

        if (reviewRepository.existsByBookingId(bookingId)) {
            throw new ReviewAlreadyExistsException(bookingId);
        }

        Review review = new Review(
                null,
                businessId,
                bookingId,
                session.userId(),
                booking.getStaffMemberId(),
                rating,
                comentario,
                LocalDateTime.now()
        );

        Review saved = reviewRepository.save(review);
        sessionService.recordSessionUsed(sessionToken, tenantId, clientIp, "create_review");
        log.info("AGENDA: reseña creada id={} businessId={} bookingId={}", saved.getId(), businessId, bookingId);
        return saved;
    }
}

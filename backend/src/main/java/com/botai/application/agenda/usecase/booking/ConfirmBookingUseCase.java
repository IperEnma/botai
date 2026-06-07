package com.botai.application.agenda.usecase.booking;

import com.botai.application.agenda.support.BookingConfirmedOutboxService;
import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Component
public class ConfirmBookingUseCase {

    private final BusinessRepository businessRepository;
    private final BookingRepository bookingRepository;
    private final BookingConfirmedOutboxService confirmedOutbox;

    public ConfirmBookingUseCase(BusinessRepository businessRepository,
                                 BookingRepository bookingRepository,
                                 BookingConfirmedOutboxService confirmedOutbox) {
        this.businessRepository = businessRepository;
        this.bookingRepository = bookingRepository;
        this.confirmedOutbox = confirmedOutbox;
    }

    @Transactional
    public Booking execute(String tenantId, UUID businessId, UUID bookingId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new BookingNotFoundException(bookingId));

        if (!businessId.equals(booking.getBusinessId())) {
            throw new BookingNotFoundException(bookingId);
        }
        if (booking.getEstado() == BookingEstado.CONFIRMED) {
            return booking;
        }
        if (booking.getEstado() != BookingEstado.PENDING) {
            throw new IllegalStateException("Solo se pueden confirmar reservas pendientes.");
        }

        Booking confirmed = new Booking(
                booking.getId(),
                booking.getBusinessId(),
                booking.getServiceId(),
                booking.getUserId(),
                booking.getSubscriptionId(),
                booking.getStaffMemberId(),
                booking.getFechaHoraInicio(),
                booking.getFechaHoraFin(),
                BookingEstado.CONFIRMED,
                booking.getNotas(),
                booking.getCanceladaAt(),
                booking.getCompletadaAt(),
                booking.getCreatedAt(),
                booking.getUpdatedAt());

        Booking saved = bookingRepository.save(confirmed);
        confirmedOutbox.enqueue(saved);
        return saved;
    }
}

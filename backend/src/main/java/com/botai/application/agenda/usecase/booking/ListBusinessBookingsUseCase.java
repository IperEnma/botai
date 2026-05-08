package com.botai.application.agenda.usecase.booking;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Lista reservas de un negocio (vista privada de empresa).
 *
 * <p>No depende de {@code X-User-Id}: es el calendario "del negocio", no "mis reservas".</p>
 */
@Service
public class ListBusinessBookingsUseCase {

    private final BookingRepository bookingRepository;
    private final BusinessRepository businessRepository;

    public ListBusinessBookingsUseCase(BookingRepository bookingRepository,
                                       BusinessRepository businessRepository) {
        this.bookingRepository = bookingRepository;
        this.businessRepository = businessRepository;
    }

    public List<Booking> execute(String tenantId,
                                 UUID businessId,
                                 LocalDateTime desde,
                                 LocalDateTime hasta) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        return bookingRepository.findAllByBusinessIdAndFecha(businessId, desde, hasta);
    }
}


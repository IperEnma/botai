package com.botai.agenda.application.usecase.booking;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.Booking;
import com.botai.agenda.domain.model.BookingEstado;
import com.botai.agenda.domain.repository.BookingRepository;
import com.botai.agenda.domain.repository.BusinessRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Lista las reservas del usuario en un negocio específico del tenant.
 * Acepta un filtro opcional por estado; si es null devuelve todas.
 */
@Service
public class ListMyBookingsUseCase {

    private final BookingRepository bookingRepository;
    private final BusinessRepository businessRepository;

    public ListMyBookingsUseCase(BookingRepository bookingRepository,
                                 BusinessRepository businessRepository) {
        this.bookingRepository = bookingRepository;
        this.businessRepository = businessRepository;
    }

    public List<Booking> execute(String tenantId, UUID businessId, UUID userId, BookingEstado estado) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        if (estado != null) {
            return bookingRepository.findAllByUserIdAndEstado(userId, estado);
        }
        return bookingRepository.findAllByUserId(userId);
    }
}

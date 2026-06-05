package com.botai.application.agenda.support;

import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.domain.agenda.exception.BookingSlotTakenException;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.domain.agenda.service.BookingDomainService;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Resuelve el profesional de una reserva cuando el cliente eligió "cualquiera disponible".
 */
@Component
public class StaffBookingAssignmentService {

    private final BookingDomainService bookingService;
    private final ServiceStaffLookup staffLookup;

    public StaffBookingAssignmentService(BookingDomainService bookingService,
                                         ServiceStaffLookup staffLookup) {
        this.bookingService = bookingService;
        this.staffLookup = staffLookup;
    }

    public UUID resolveStaffMemberId(UUID businessId,
                                     Service service,
                                     UUID requestedStaffId,
                                     LocalDateTime inicio,
                                     LocalDateTime fin) {
        if (requestedStaffId != null) {
            assertEligible(businessId, service.getId(), requestedStaffId);
            bookingService.validarDisponibilidad(businessId, requestedStaffId, inicio, fin);
            return requestedStaffId;
        }
        if (service.getSchedulingMode() != ServiceSchedulingMode.BY_STAFF) {
            return null;
        }
        List<UUID> eligible = staffLookup.eligibleStaffForService(businessId, service.getId());
        for (UUID staffId : eligible) {
            try {
                bookingService.validarDisponibilidad(businessId, staffId, inicio, fin);
                return staffId;
            } catch (BookingSlotTakenException ignored) {
                // Probar con el siguiente profesional libre.
            }
        }
        throw new BookingSlotTakenException();
    }

    private void assertEligible(UUID businessId, UUID serviceId, UUID staffMemberId) {
        List<UUID> eligible = staffLookup.eligibleStaffForService(businessId, serviceId);
        if (!eligible.contains(staffMemberId)) {
            throw new IllegalArgumentException("El profesional no atiende este servicio.");
        }
    }
}

package com.botai.application.agenda.usecase.booking;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.application.agenda.support.BookingConfirmedOutboxService;
import com.botai.application.agenda.support.StaffBookingAssignmentService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Component
public class CreateTenantPendingBookingUseCase {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final UserRepository userRepository;
    private final BookingRepository bookingRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final StaffBookingAssignmentService staffAssignment;
    private final BookingConfirmedOutboxService confirmedOutbox;

    public CreateTenantPendingBookingUseCase(BusinessRepository businessRepository,
                                             ServiceRepository serviceRepository,
                                             UserRepository userRepository,
                                             BookingRepository bookingRepository,
                                             BusinessSettingsRepository settingsRepository,
                                             StaffBookingAssignmentService staffAssignment,
                                             BookingConfirmedOutboxService confirmedOutbox) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
        this.userRepository = userRepository;
        this.bookingRepository = bookingRepository;
        this.settingsRepository = settingsRepository;
        this.staffAssignment = staffAssignment;
        this.confirmedOutbox = confirmedOutbox;
    }

    @Transactional
    public Booking execute(String tenantId,
                           UUID businessId,
                           UUID clientId,
                           UUID serviceId,
                           UUID staffMemberId,
                           LocalDateTime fechaHoraInicio,
                           String notas) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        User client = userRepository.findById(clientId)
                .orElseThrow(() -> new IllegalArgumentException("Cliente no encontrado"));
        if (!tenantId.equals(client.getTenantId())) {
            throw new IllegalArgumentException("Cliente no pertenece a este tenant");
        }
        if (!AgendaPhoneNormalizer.isValid(client.getTelefono())) {
            throw new IllegalArgumentException("El cliente debe tener teléfono para reservar");
        }

        Service service = serviceRepository.findById(serviceId)
                .orElseThrow(() -> new ServiceNotFoundException(serviceId));
        if (!service.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(serviceId);
        }

        LocalDateTime fin = fechaHoraInicio.plusMinutes(service.getDuracionMin());
        UUID resolvedStaff = staffAssignment.resolveStaffMemberId(
                businessId, service, staffMemberId, fechaHoraInicio, fin);

        BusinessSettings settings = settingsRepository.findByBusinessId(businessId)
                .orElseGet(() -> BusinessSettings.defaults(businessId));
        BookingEstado estado = settings.isRequireBookingConfirmation()
                ? BookingEstado.PENDING
                : BookingEstado.CONFIRMED;

        Booking booking = new Booking(
                null,
                businessId,
                serviceId,
                clientId,
                null,
                resolvedStaff,
                fechaHoraInicio,
                fin,
                estado,
                notas,
                null,
                null,
                null,
                null
        );
        Booking saved = bookingRepository.save(booking);
        if (estado == BookingEstado.CONFIRMED) {
            confirmedOutbox.enqueue(saved);
        }
        return saved;
    }
}

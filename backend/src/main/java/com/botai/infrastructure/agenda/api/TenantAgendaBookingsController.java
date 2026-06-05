package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.dto.TenantCreatePendingBookingRequest;
import com.botai.application.agenda.mapper.BookingDtoMapper;
import com.botai.application.agenda.usecase.booking.CreateTenantPendingBookingUseCase;
import com.botai.application.agenda.usecase.booking.ListBusinessBookingsUseCase;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.UserRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Calendario privado de empresa: turnos tomados para un negocio.
 *
 * <p>Scope: admin de tenant (panel privado). No requiere {@code X-User-Id}.</p>
 */
@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/agenda")
@Tag(name = "Agenda Me · Business Agenda", description = "Calendario privado del negocio (admin)")
@Validated
public class TenantAgendaBookingsController {

    private final ListBusinessBookingsUseCase listBusinessBookings;
    private final CreateTenantPendingBookingUseCase createTenantPendingBooking;
    private final AgendaCurrentTenantService currentTenant;
    private final ServiceRepository serviceRepository;
    private final UserRepository userRepository;

    public TenantAgendaBookingsController(ListBusinessBookingsUseCase listBusinessBookings,
                                          CreateTenantPendingBookingUseCase createTenantPendingBooking,
                                          AgendaCurrentTenantService currentTenant,
                                          ServiceRepository serviceRepository,
                                          UserRepository userRepository) {
        this.listBusinessBookings = listBusinessBookings;
        this.createTenantPendingBooking = createTenantPendingBooking;
        this.currentTenant = currentTenant;
        this.serviceRepository = serviceRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/bookings")
    @Operation(summary = "Listar reservas del negocio en un rango de fechas")
    public ResponseEntity<List<BookingResponse>> list(
            @PathVariable("businessId") UUID businessId,
            @RequestParam("from")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam("to")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to
    ) {
        String tenantId = currentTenant.requireBusinessOwnedByCurrentTenant(businessId).getTenantId();

        List<BookingResponse> responses = listBusinessBookings.execute(tenantId, businessId, from, to)
                .stream()
                .map(b -> {
                    String serviceName = serviceRepository.findById(b.getServiceId())
                            .map(s -> s.getNombre())
                            .orElse(null);
                    User user = userRepository.findById(b.getUserId()).orElse(null);
                    return BookingDtoMapper.toResponse(b, serviceName, user);
                })
                .toList();
        return ResponseEntity.ok(responses);
    }

    @PostMapping("/bookings")
    @Operation(summary = "Crear reserva PENDING para un cliente (panel tenant)")
    public ResponseEntity<BookingResponse> createPending(
            @PathVariable("businessId") UUID businessId,
            @Valid @RequestBody TenantCreatePendingBookingRequest request) {
        String tenantId = currentTenant.requireBusinessOwnedByCurrentTenant(businessId).getTenantId();
        var booking = createTenantPendingBooking.execute(
                tenantId,
                businessId,
                request.clientId(),
                request.serviceId(),
                request.staffMemberId(),
                request.fechaHoraInicio(),
                request.notas());
        String serviceName = serviceRepository.findById(booking.getServiceId())
                .map(s -> s.getNombre())
                .orElse(null);
        User user = userRepository.findById(booking.getUserId()).orElse(null);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BookingDtoMapper.toResponse(booking, serviceName, user));
    }
}


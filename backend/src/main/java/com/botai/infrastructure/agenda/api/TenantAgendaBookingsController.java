package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.dto.TenantCreatePendingBookingRequest;
import com.botai.application.agenda.mapper.BookingDtoMapper;
import com.botai.application.agenda.security.AgendaAuthorizationService;
import com.botai.application.agenda.security.AgendaUserPrincipal;
import com.botai.application.agenda.usecase.booking.ConfirmBookingUseCase;
import com.botai.application.agenda.usecase.booking.CreateTenantPendingBookingUseCase;
import com.botai.application.agenda.usecase.booking.ListBusinessBookingsUseCase;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.UserRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import com.botai.infrastructure.agenda.security.AgendaUserContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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
    private final ConfirmBookingUseCase confirmBooking;
    private final AgendaCurrentTenantService currentTenant;
    private final ServiceRepository serviceRepository;
    private final UserRepository userRepository;
    private final AgendaUserContext userContext;
    private final AgendaAuthorizationService authz;

    public TenantAgendaBookingsController(ListBusinessBookingsUseCase listBusinessBookings,
                                          CreateTenantPendingBookingUseCase createTenantPendingBooking,
                                          ConfirmBookingUseCase confirmBooking,
                                          AgendaCurrentTenantService currentTenant,
                                          ServiceRepository serviceRepository,
                                          UserRepository userRepository,
                                          AgendaUserContext userContext,
                                          AgendaAuthorizationService authz) {
        this.listBusinessBookings = listBusinessBookings;
        this.createTenantPendingBooking = createTenantPendingBooking;
        this.confirmBooking = confirmBooking;
        this.currentTenant = currentTenant;
        this.serviceRepository = serviceRepository;
        this.userRepository = userRepository;
        this.userContext = userContext;
        this.authz = authz;
    }

    @GetMapping("/bookings")
    @Operation(summary = "Listar reservas del negocio en un rango de fechas")
    @PreAuthorize("@authz.canViewAgenda(#businessId)")
    public ResponseEntity<List<BookingResponse>> list(
            @PathVariable("businessId") UUID businessId,
            @RequestParam("from")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam("to")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to
    ) {
        String tenantId = currentTenant.requireBusinessOwnedByCurrentTenant(businessId).getTenantId();

        // Filtro server-side: STAFF (operator/viewer) sin rol administrativo ni
        // de recepción ve solo SUS reservas. Para OW/TA/RC, sin filtro (toda la
        // agenda del negocio).
        AgendaUserPrincipal pr = userContext.principal();
        UUID staffFilter = null;
        boolean isStaffOnly = !pr.isAdministrative()
                && !pr.hasBusinessRole(Role.RECEPTION, businessId)
                && pr.hasAnyBusinessRole(businessId,
                        Role.STAFF_OPERATOR, Role.STAFF_VIEWER);
        if (isStaffOnly) {
            // Si no resuelve staffMember para esta sucursal, forzamos un id
            // imposible para devolver lista vacía sin filtrar las de otros.
            staffFilter = authz.currentUserStaffMemberId(businessId)
                    .orElse(new UUID(0L, 0L));
        }

        List<BookingResponse> responses = listBusinessBookings
                .execute(tenantId, businessId, from, to, staffFilter)
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
    @Operation(summary = "Crear reserva para un cliente (PENDING o CONFIRMED según configuración)")
    @PreAuthorize("@authz.canManageBookingFor(#businessId, #request.staffMemberId())")
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

    @PutMapping("/bookings/{bookingId}/confirm")
    @Operation(summary = "Confirmar una reserva pendiente")
    @PreAuthorize("@authz.canManageAgenda(#businessId)")
    public ResponseEntity<BookingResponse> confirm(
            @PathVariable("businessId") UUID businessId,
            @PathVariable("bookingId") UUID bookingId) {
        String tenantId = currentTenant.requireBusinessOwnedByCurrentTenant(businessId).getTenantId();
        var booking = confirmBooking.execute(tenantId, businessId, bookingId);
        String serviceName = serviceRepository.findById(booking.getServiceId())
                .map(s -> s.getNombre())
                .orElse(null);
        User user = userRepository.findById(booking.getUserId()).orElse(null);
        return ResponseEntity.ok(BookingDtoMapper.toResponse(booking, serviceName, user));
    }
}


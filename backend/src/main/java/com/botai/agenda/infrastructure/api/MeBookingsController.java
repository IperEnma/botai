package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.BookingResponse;
import com.botai.agenda.application.dto.CreateBookingRequest;
import com.botai.agenda.application.mapper.BookingDtoMapper;
import com.botai.agenda.application.usecase.booking.CancelBookingUseCase;
import com.botai.agenda.application.usecase.booking.CreateBookingUseCase;
import com.botai.agenda.application.usecase.booking.ListMyBookingsUseCase;
import com.botai.agenda.domain.model.BookingEstado;
import com.botai.agenda.domain.repository.BusinessRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Bookings", description = "Reservas del usuario final autenticado")
@Validated
public class MeBookingsController {

    private static final String USER_ID_HEADER = "X-User-Id";

    private final CreateBookingUseCase createBooking;
    private final ListMyBookingsUseCase listMyBookings;
    private final CancelBookingUseCase cancelBooking;
    private final BusinessRepository businessRepository;

    public MeBookingsController(CreateBookingUseCase createBooking,
                                ListMyBookingsUseCase listMyBookings,
                                CancelBookingUseCase cancelBooking,
                                BusinessRepository businessRepository) {
        this.createBooking = createBooking;
        this.listMyBookings = listMyBookings;
        this.cancelBooking = cancelBooking;
        this.businessRepository = businessRepository;
    }

    @GetMapping("/businesses/{businessId}/bookings")
    @Operation(summary = "Listar mis reservas en un negocio (filtro opcional por estado)")
    public ResponseEntity<List<BookingResponse>> list(
            @PathVariable("businessId") UUID businessId,
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @RequestParam(value = "estado", required = false) BookingEstado estado) {
        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new IllegalArgumentException("Negocio no encontrado: " + businessId));
        List<BookingResponse> responses = listMyBookings.execute(tenantId, businessId, userId, estado)
                .stream()
                .map(BookingDtoMapper::toResponse)
                .toList();
        return ResponseEntity.ok(responses);
    }

    @DeleteMapping("/businesses/{businessId}/bookings/{bookingId}")
    @Operation(summary = "Cancelar una reserva propia (dentro de la ventana de cancelación)")
    public ResponseEntity<Void> cancel(
            @PathVariable("businessId") UUID businessId,
            @PathVariable("bookingId") UUID bookingId,
            @RequestHeader(USER_ID_HEADER) UUID userId) {
        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new IllegalArgumentException("Negocio no encontrado: " + businessId));
        cancelBooking.execute(tenantId, businessId, userId, bookingId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/businesses/{businessId}/bookings")
    @Operation(summary = "Crear una reserva confirmada contra un servicio del negocio")
    public ResponseEntity<BookingResponse> create(
            @PathVariable("businessId") UUID businessId,
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @Valid @RequestBody CreateBookingRequest request) {
        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new IllegalArgumentException("Negocio no encontrado: " + businessId));
        var booking = createBooking.execute(
                tenantId,
                businessId,
                userId,
                request.serviceId(),
                request.subscriptionId(),
                request.staffMemberId(),
                request.fechaHoraInicio(),
                request.notas());
        return ResponseEntity.status(HttpStatus.CREATED).body(BookingDtoMapper.toResponse(booking));
    }
}

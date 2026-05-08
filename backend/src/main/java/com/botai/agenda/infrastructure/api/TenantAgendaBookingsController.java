package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.BookingResponse;
import com.botai.agenda.application.mapper.BookingDtoMapper;
import com.botai.agenda.application.usecase.booking.ListBusinessBookingsUseCase;
import com.botai.agenda.domain.repository.BusinessRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
    private final BusinessRepository businessRepository;

    public TenantAgendaBookingsController(ListBusinessBookingsUseCase listBusinessBookings,
                                          BusinessRepository businessRepository) {
        this.listBusinessBookings = listBusinessBookings;
        this.businessRepository = businessRepository;
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
        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new IllegalArgumentException("Negocio no encontrado: " + businessId));

        List<BookingResponse> responses = listBusinessBookings.execute(tenantId, businessId, from, to)
                .stream()
                .map(BookingDtoMapper::toResponse)
                .toList();
        return ResponseEntity.ok(responses);
    }
}


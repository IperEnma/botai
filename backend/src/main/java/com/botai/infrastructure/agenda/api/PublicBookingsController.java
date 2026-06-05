package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.dto.PublicCreateBookingRequest;
import com.botai.application.agenda.mapper.BookingDtoMapper;
import com.botai.application.agenda.support.AgendaClientResolver;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.UserRepository;
import com.botai.domain.agenda.service.BookingDomainService;
import com.botai.infrastructure.agenda.support.HttpRequestClientIp;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/public")
@Tag(name = "Agenda Public · Bookings", description = "Reservas desde la vista pública (clientes)")
public class PublicBookingsController {

    private final BusinessRepository businessRepository;
    private final ServiceRepository serviceRepository;
    private final UserRepository userRepository;
    private final BookingRepository bookingRepository;
    private final BookingDomainService bookingService;
    private final AgendaPublicClientSessionService sessionService;

    public PublicBookingsController(BusinessRepository businessRepository,
                                    ServiceRepository serviceRepository,
                                    UserRepository userRepository,
                                    BookingRepository bookingRepository,
                                    BookingDomainService bookingService,
                                    AgendaPublicClientSessionService sessionService) {
        this.businessRepository = businessRepository;
        this.serviceRepository = serviceRepository;
        this.userRepository = userRepository;
        this.bookingRepository = bookingRepository;
        this.bookingService = bookingService;
        this.sessionService = sessionService;
    }

    @PostMapping("/businesses/{businessId}/bookings")
    @Operation(summary = "Solicitar un turno (PENDING) en un negocio")
    public ResponseEntity<BookingResponse> create(
            @PathVariable("businessId") UUID businessId,
            @RequestHeader(value = AgendaPublicClientSessionService.SESSION_HEADER, required = false)
            String sessionToken,
            @Valid @RequestBody PublicCreateBookingRequest request,
            HttpServletRequest httpRequest) {

        final String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        String clientIp = HttpRequestClientIp.resolve(httpRequest);

        Service service = serviceRepository.findById(request.serviceId())
                .orElseThrow(() -> new ServiceNotFoundException(request.serviceId()));
        if (!service.getBusinessId().equals(businessId)) {
            throw new ServiceNotFoundException(request.serviceId());
        }

        User user = resolveBookingClient(tenantId, sessionToken, request, clientIp);

        LocalDateTime inicio = request.fechaHoraInicio();
        LocalDateTime fin = inicio.plusMinutes(service.getDuracionMin());
        bookingService.validarDisponibilidad(businessId, request.staffMemberId(), inicio, fin);

        Booking pending = new Booking(
                null,
                businessId,
                request.serviceId(),
                user.getId(),
                null,
                request.staffMemberId(),
                inicio,
                fin,
                BookingEstado.PENDING,
                request.notas(),
                null,
                null,
                null,
                null
        );
        Booking saved = bookingRepository.save(pending);
        if (sessionToken != null && !sessionToken.isBlank()) {
            sessionService.recordSessionUsed(sessionToken, tenantId, clientIp, "create_booking");
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(BookingDtoMapper.toResponse(saved));
    }

    private User resolveBookingClient(String tenantId,
                                      String sessionToken,
                                      PublicCreateBookingRequest request,
                                      String clientIp) {
        if (request.clientId() != null) {
            User existing = userRepository.findById(request.clientId())
                    .orElseThrow(() -> new IllegalArgumentException("Cliente no encontrado"));
            if (!AgendaPhoneNormalizer.isValid(existing.getTelefono())) {
                throw new IllegalArgumentException("El cliente debe tener teléfono para reservar");
            }
            return existing;
        }

        AgendaPublicClientSessionService.ClientSession session =
                sessionService.requireSessionForTenant(sessionToken, tenantId, clientIp);
        User user = userRepository.findById(session.userId())
                .orElseThrow(() -> new IllegalArgumentException("Cliente no encontrado"));

        if (request.telefonoCliente() != null && !request.telefonoCliente().isBlank()) {
            String norm = AgendaPhoneNormalizer.normalize(request.telefonoCliente());
            if (!norm.equals(session.phoneNormalized())) {
                throw new IllegalArgumentException("Teléfono no coincide con la sesión verificada.");
            }
        }

        boolean needsName = AgendaClientResolver.PENDING_NAME.equals(user.getNombre());
        if (needsName) {
            if (request.nombreCliente() == null || request.nombreCliente().isBlank()) {
                throw new IllegalArgumentException("Nombre obligatorio en tu primera reserva.");
            }
            return AgendaClientResolver.resolveOrCreate(
                    userRepository,
                    tenantId,
                    request.nombreCliente(),
                    request.emailCliente(),
                    session.phoneNormalized());
        }

        if (request.emailCliente() != null && !request.emailCliente().isBlank()) {
            return AgendaClientResolver.resolveOrCreate(
                    userRepository,
                    tenantId,
                    user.getNombre(),
                    request.emailCliente(),
                    session.phoneNormalized());
        }
        return user;
    }
}

package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.AvailabilitySlotResponse;
import com.botai.agenda.application.dto.BusinessResponse;
import com.botai.agenda.application.dto.ServiceResponse;
import com.botai.agenda.application.dto.StaffMemberResponse;
import com.botai.agenda.application.mapper.BusinessDtoMapper;
import com.botai.agenda.application.mapper.ServiceDtoMapper;
import com.botai.agenda.application.mapper.StaffMemberDtoMapper;
import com.botai.agenda.application.usecase.business.ListBusinessServicesUseCase;
import com.botai.agenda.application.usecase.staff.ListPublicStaffUseCase;
import com.botai.agenda.domain.model.BookingEstado;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessHours;
import com.botai.agenda.domain.repository.BookingRepository;
import com.botai.agenda.domain.repository.BusinessCategoryRepository;
import com.botai.agenda.domain.repository.BusinessHoursRepository;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.ServiceRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Endpoints públicos por slug (no exponen el UUID en la URL).
 *
 * <p>El slug se resuelve internamente al {@link Business} y se usan los mismos DTOs que
 * el directorio público.</p>
 */
@RestController
@RequestMapping("/api/agenda/public/businesses/by-slug/{slug}")
@Tag(name = "Agenda Public · By slug", description = "Acceso público a negocio via slug amigable")
public class PublicBusinessBySlugController {

    private final BusinessRepository businessRepository;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final ListBusinessServicesUseCase listBusinessServices;
    private final ListPublicStaffUseCase listPublicStaff;
    private final ServiceRepository serviceRepository;
    private final BusinessHoursRepository hoursRepository;
    private final BookingRepository bookingRepository;

    public PublicBusinessBySlugController(BusinessRepository businessRepository,
                                          BusinessCategoryRepository businessCategoryRepository,
                                          ListBusinessServicesUseCase listBusinessServices,
                                          ListPublicStaffUseCase listPublicStaff,
                                          ServiceRepository serviceRepository,
                                          BusinessHoursRepository hoursRepository,
                                          BookingRepository bookingRepository) {
        this.businessRepository = businessRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.listBusinessServices = listBusinessServices;
        this.listPublicStaff = listPublicStaff;
        this.serviceRepository = serviceRepository;
        this.hoursRepository = hoursRepository;
        this.bookingRepository = bookingRepository;
    }

    private Business requireBusiness(String slug) {
        return businessRepository.findByPublicSlug(slug)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Negocio no encontrado"));
    }

    @GetMapping
    @Operation(summary = "Ficha pública completa de un negocio por slug")
    public BusinessResponse business(@PathVariable("slug") String slug) {
        Business b = requireBusiness(slug);
        var categories = businessCategoryRepository.findCategorySlugsByBusinessId(b.getId());
        return BusinessDtoMapper.toResponse(b, categories);
    }

    @GetMapping("/services")
    @Operation(summary = "Servicios activos de un negocio por slug")
    public List<ServiceResponse> services(@PathVariable("slug") String slug) {
        Business b = requireBusiness(slug);
        return listBusinessServices.execute(b.getId()).stream()
                .map(ServiceDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/staff")
    @Operation(summary = "Miembros activos del equipo de un negocio por slug")
    public List<StaffMemberResponse> staff(@PathVariable("slug") String slug) {
        Business b = requireBusiness(slug);
        return listPublicStaff.execute(b.getId()).stream()
                .map(StaffMemberDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/availability")
    @Operation(summary = "Turnos disponibles para un servicio en una fecha (por slug)")
    public List<AvailabilitySlotResponse> availability(
            @PathVariable("slug") String slug,
            @RequestParam("serviceId") UUID serviceId,
            @RequestParam(value = "staffMemberId", required = false) UUID staffMemberId,
            @RequestParam("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {

        Business b = requireBusiness(slug);

        var service = serviceRepository.findById(serviceId).orElse(null);
        if (service == null) return List.of();

        int duracionMin = service.getDuracionMin();

        int diaSemana = date.getDayOfWeek().getValue() - 1;
        Optional<BusinessHours> hoursOpt = hoursRepository.findByBusinessId(b.getId())
                .stream()
                .filter(h -> h.getDiaSemana() == diaSemana)
                .findFirst();

        if (hoursOpt.isEmpty() || hoursOpt.get().isCerrado()) {
            return List.of();
        }

        BusinessHours hours = hoursOpt.get();
        LocalTime apertura = hours.getApertura();
        LocalTime cierre = hours.getCierre();

        LocalDateTime dayStart = date.atStartOfDay();
        LocalDateTime dayEnd = dayStart.plusDays(1);
        var busyBookings = bookingRepository
                .findAllByBusinessIdAndFecha(b.getId(), dayStart, dayEnd)
                .stream()
                .filter(x -> x.getEstado() == BookingEstado.PENDING
                        || x.getEstado() == BookingEstado.CONFIRMED)
                .filter(x -> staffMemberId == null
                        || staffMemberId.equals(x.getStaffMemberId()))
                .toList();

        List<AvailabilitySlotResponse> slots = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime cursor = date.atTime(apertura);
        LocalDateTime closeAt = date.atTime(cierre);

        while (!cursor.plusMinutes(duracionMin).isAfter(closeAt)) {
            final LocalDateTime slotStart = cursor;
            final LocalDateTime slotEnd = cursor.plusMinutes(duracionMin);
            if (!slotStart.isBefore(now)) {
                boolean busy = busyBookings.stream().anyMatch(x ->
                        slotStart.isBefore(x.getFechaHoraFin())
                                && slotEnd.isAfter(x.getFechaHoraInicio()));
                if (!busy) {
                    slots.add(new AvailabilitySlotResponse(slotStart.toString(), slotEnd.toString()));
                }
            }
            cursor = slotEnd;
        }
        return slots;
    }
}


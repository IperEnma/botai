package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AvailabilitySlotResponse;
import com.botai.application.agenda.dto.BusinessHoursResponse;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.mapper.StaffMemberDtoMapper;
import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.usecase.staff.ListPublicStaffUseCase;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.util.Map;
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
    private final StaffMemberRepository staffMemberRepository;
    private final ObjectMapper objectMapper;
    private final ServiceStaffLookup serviceStaffLookup;

    public PublicBusinessBySlugController(BusinessRepository businessRepository,
                                          BusinessCategoryRepository businessCategoryRepository,
                                          ListBusinessServicesUseCase listBusinessServices,
                                          ListPublicStaffUseCase listPublicStaff,
                                          ServiceRepository serviceRepository,
                                          BusinessHoursRepository hoursRepository,
                                          BookingRepository bookingRepository,
                                          StaffMemberRepository staffMemberRepository,
                                          ObjectMapper objectMapper,
                                          ServiceStaffLookup serviceStaffLookup) {
        this.businessRepository = businessRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.listBusinessServices = listBusinessServices;
        this.listPublicStaff = listPublicStaff;
        this.serviceRepository = serviceRepository;
        this.hoursRepository = hoursRepository;
        this.bookingRepository = bookingRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.objectMapper = objectMapper;
        this.serviceStaffLookup = serviceStaffLookup;
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
        Map<UUID, List<UUID>> staffByService = serviceStaffLookup.staffIdsByServiceId(b.getId());
        return listBusinessServices.execute(b.getId()).stream()
                .map(s -> ServiceDtoMapper.toResponse(
                        s, staffByService.getOrDefault(s.getId(), List.of())))
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

    @GetMapping("/hours")
    @Operation(summary = "Horarios de atención publicados (por slug)")
    public List<BusinessHoursResponse> hours(@PathVariable("slug") String slug) {
        Business b = requireBusiness(slug);
        return hoursRepository.findByBusinessId(b.getId()).stream()
                .map(h -> new BusinessHoursResponse(
                        h.getId(),
                        h.getBusinessId(),
                        h.getDiaSemana(),
                        h.getApertura(),
                        h.getCierre(),
                        h.getApertura2(),
                        h.getCierre2(),
                        h.isCerrado()
                ))
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

        final BusinessHours hours;
        if (hoursOpt.isPresent()) {
            if (hoursOpt.get().isCerrado()) return List.of();
            hours = hoursOpt.get();
        } else {
            hours = defaultHours(b.getId(), diaSemana).orElse(null);
            if (hours == null || hours.isCerrado()) return List.of();
        }

        LocalTime apertura = hours.getApertura();
        LocalTime cierre = hours.getCierre();

        // Override with the staff member's own schedule when they have one configured
        if (staffMemberId != null) {
            var staffOpt = staffMemberRepository.findById(staffMemberId);
            if (staffOpt.isPresent() && staffOpt.get().getCustomSchedule() != null) {
                String[] dayKeys = {"lunes","martes","miercoles","jueves","viernes","sabado","domingo"};
                try {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> sched = objectMapper.readValue(staffOpt.get().getCustomSchedule(), Map.class);
                    @SuppressWarnings("unchecked")
                    Map<String, Object> dayEntry = (Map<String, Object>) sched.get(dayKeys[diaSemana]);
                    if (dayEntry == null || !Boolean.TRUE.equals(dayEntry.get("open"))) {
                        return List.of();
                    }
                    String fromStr = (String) dayEntry.get("from");
                    String toStr   = (String) dayEntry.get("to");
                    if (fromStr != null) {
                        LocalTime staffFrom = LocalTime.parse(fromStr);
                        if (staffFrom.isAfter(apertura)) apertura = staffFrom;
                    }
                    if (toStr != null) {
                        LocalTime staffTo = LocalTime.parse(toStr);
                        if (staffTo.isBefore(cierre)) cierre = staffTo;
                    }
                    if (!apertura.isBefore(cierre)) return List.of();
                } catch (Exception ignored) { /* fall back to business hours on parse error */ }
            }
        }

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

    private Optional<BusinessHours> defaultHours(UUID businessId, int diaSemana) {
        if (diaSemana == 6) {
            return Optional.of(new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                    LocalTime.of(9, 0), LocalTime.of(13, 0), null, null, true));
        }
        if (diaSemana == 5) {
            return Optional.of(new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                    LocalTime.of(9, 0), LocalTime.of(13, 0), null, null, false));
        }
        return Optional.of(new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false));
    }
}


package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AvailabilitySlotResponse;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.BusinessSummaryResponse;
import com.botai.application.agenda.dto.CategoryResponse;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.mapper.CategoryDtoMapper;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.mapper.StaffMemberDtoMapper;
import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.usecase.category.ListPublicCategoriesUseCase;
import com.botai.application.agenda.usecase.search.GetBusinessPublicUseCase;
import com.botai.application.agenda.usecase.search.ListBusinessesByCategoryUseCase;
import com.botai.application.agenda.usecase.search.SearchBusinessesUseCase;
import com.botai.application.agenda.usecase.staff.ListPublicStaffUseCase;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.BookingEstado;
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
import org.springframework.format.annotation.DateTimeFormat;
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

/** Endpoints públicos del directorio AGENDA (no requieren auth). */
@RestController
@RequestMapping("/api/agenda/public")
@Tag(name = "Agenda Public", description = "Buscador y directorio públicos")
public class PublicSearchController {

    private final SearchBusinessesUseCase searchBusinesses;
    private final ListPublicCategoriesUseCase listCategories;
    private final ListBusinessesByCategoryUseCase listByCategory;
    private final GetBusinessPublicUseCase getBusinessPublic;
    private final ListBusinessServicesUseCase listBusinessServices;
    private final ListPublicStaffUseCase listPublicStaff;
    private final BusinessRepository businessRepository;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final ServiceRepository serviceRepository;
    private final BusinessHoursRepository hoursRepository;
    private final BookingRepository bookingRepository;
    private final StaffMemberRepository staffMemberRepository;
    private final ObjectMapper objectMapper;
    private final ServiceStaffLookup serviceStaffLookup;

    public PublicSearchController(SearchBusinessesUseCase searchBusinesses,
                                  ListPublicCategoriesUseCase listCategories,
                                  ListBusinessesByCategoryUseCase listByCategory,
                                  GetBusinessPublicUseCase getBusinessPublic,
                                  ListBusinessServicesUseCase listBusinessServices,
                                  ListPublicStaffUseCase listPublicStaff,
                                  BusinessRepository businessRepository,
                                  BusinessCategoryRepository businessCategoryRepository,
                                  ServiceRepository serviceRepository,
                                  BusinessHoursRepository hoursRepository,
                                  BookingRepository bookingRepository,
                                  StaffMemberRepository staffMemberRepository,
                                  ObjectMapper objectMapper,
                                  ServiceStaffLookup serviceStaffLookup) {
        this.searchBusinesses = searchBusinesses;
        this.listCategories = listCategories;
        this.listByCategory = listByCategory;
        this.getBusinessPublic = getBusinessPublic;
        this.listBusinessServices = listBusinessServices;
        this.listPublicStaff = listPublicStaff;
        this.businessRepository = businessRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.serviceRepository = serviceRepository;
        this.hoursRepository = hoursRepository;
        this.bookingRepository = bookingRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.objectMapper = objectMapper;
        this.serviceStaffLookup = serviceStaffLookup;
    }

    @GetMapping("/search")
    @Operation(summary = "Busca negocios por término (usa sinónimos del catálogo)")
    public List<BusinessSummaryResponse> search(@RequestParam("q") String q,
                                                @RequestParam(value = "tenantId", required = false) String tenantId,
                                                @RequestParam(value = "limit", defaultValue = "20") int limit,
                                                @RequestParam(value = "offset", defaultValue = "0") int offset) {
        return searchBusinesses.execute(q, tenantId, limit, offset).stream()
                .map(BusinessDtoMapper::toSummaryResponse)
                .toList();
    }

    @GetMapping("/categories")
    @Operation(summary = "Listado público de categorías activas")
    public List<CategoryResponse> categories() {
        return listCategories.listActive().stream()
                .map(CategoryDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/categories/{slug}/businesses")
    @Operation(summary = "Negocios de una categoría")
    public List<BusinessSummaryResponse> businessesByCategory(
            @PathVariable("slug") String slug,
            @RequestParam(value = "limit", defaultValue = "20") int limit,
            @RequestParam(value = "offset", defaultValue = "0") int offset) {
        return listByCategory.execute(slug, limit, offset).stream()
                .map(BusinessDtoMapper::toSummaryResponse)
                .toList();
    }

    @GetMapping("/businesses/{id}")
    @Operation(summary = "Ficha pública completa de un negocio (incluye estilos)")
    public BusinessResponse business(@PathVariable("id") UUID id) {
        var b = businessRepository.findById(id)
                .orElseThrow(() -> new BusinessNotFoundException(id));
        var categories = businessCategoryRepository.findCategorySlugsByBusinessId(id);
        return BusinessDtoMapper.toResponse(b, categories);
    }

    @GetMapping("/businesses/{id}/services")
    @Operation(summary = "Servicios activos de un negocio")
    public List<ServiceResponse> services(@PathVariable("id") UUID id) {
        Map<UUID, List<UUID>> staffByService = serviceStaffLookup.staffIdsByServiceId(id);
        return listBusinessServices.execute(id).stream()
                .map(s -> ServiceDtoMapper.toResponse(
                        s, staffByService.getOrDefault(s.getId(), List.of())))
                .toList();
    }

    @GetMapping("/businesses/{businessId}/staff")
    @Operation(summary = "Miembros activos del equipo de un negocio")
    public List<StaffMemberResponse> listStaff(@PathVariable("businessId") UUID businessId) {
        return listPublicStaff.execute(businessId).stream()
                .map(StaffMemberDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/businesses/{businessId}/availability")
    @Operation(summary = "Turnos disponibles para un servicio en una fecha")
    public List<AvailabilitySlotResponse> availability(
            @PathVariable("businessId") UUID businessId,
            @RequestParam("serviceId") UUID serviceId,
            @RequestParam(value = "staffMemberId", required = false) UUID staffMemberId,
            @RequestParam("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {

        var service = serviceRepository.findById(serviceId).orElse(null);
        if (service == null) return List.of();

        int duracionMin = service.getDuracionMin();

        // day-of-week: ISO weekday 1=MON..7=SUN → our model 0=lun..6=dom
        int diaSemana = date.getDayOfWeek().getValue() - 1;
        Optional<BusinessHours> hoursOpt = hoursRepository.findByBusinessId(businessId)
                .stream()
                .filter(h -> h.getDiaSemana() == diaSemana)
                .findFirst();

        final BusinessHours hours;
        if (hoursOpt.isPresent()) {
            if (hoursOpt.get().isCerrado()) return List.of();
            hours = hoursOpt.get();
        } else {
            // Fallback: si el negocio no configuró horarios, asumimos defaults para no bloquear el onboarding.
            // (lun-vie 09-18, sáb 09-13, dom cerrado)
            hours = defaultHours(businessId, diaSemana).orElse(null);
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

        // Existing active bookings for that business/date
        LocalDateTime dayStart = date.atStartOfDay();
        LocalDateTime dayEnd = dayStart.plusDays(1);
        var busyBookings = bookingRepository
                .findAllByBusinessIdAndFecha(businessId, dayStart, dayEnd)
                .stream()
                .filter(b -> b.getEstado() == BookingEstado.PENDING
                        || b.getEstado() == BookingEstado.CONFIRMED)
                .filter(b -> staffMemberId == null
                        || staffMemberId.equals(b.getStaffMemberId()))
                .toList();

        // Generate slots
        List<AvailabilitySlotResponse> slots = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime cursor = date.atTime(apertura);
        LocalDateTime closeAt = date.atTime(cierre);

        while (!cursor.plusMinutes(duracionMin).isAfter(closeAt)) {
            final LocalDateTime slotStart = cursor;
            final LocalDateTime slotEnd = cursor.plusMinutes(duracionMin);

            if (!slotStart.isBefore(now)) {
                boolean busy = busyBookings.stream().anyMatch(b ->
                        slotStart.isBefore(b.getFechaHoraFin())
                                && slotEnd.isAfter(b.getFechaHoraInicio()));
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

package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AvailabilitySlotResponse;
import com.botai.application.agenda.dto.BusinessHoursResponse;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.mapper.StaffMemberDtoMapper;
import com.botai.application.agenda.service.PublicAvailabilityService;
import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.usecase.staff.ListPublicStaffUseCase;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.model.RatingSummary;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ReviewRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
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
import java.util.List;
import java.util.Map;
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
    private final PublicAvailabilityService publicAvailabilityService;
    private final ServiceStaffLookup serviceStaffLookup;
    private final ReviewRepository reviewRepository;

    public PublicBusinessBySlugController(BusinessRepository businessRepository,
                                          BusinessCategoryRepository businessCategoryRepository,
                                          ListBusinessServicesUseCase listBusinessServices,
                                          ListPublicStaffUseCase listPublicStaff,
                                          ServiceRepository serviceRepository,
                                          BusinessHoursRepository hoursRepository,
                                          PublicAvailabilityService publicAvailabilityService,
                                          ServiceStaffLookup serviceStaffLookup,
                                          ReviewRepository reviewRepository) {
        this.businessRepository = businessRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.listBusinessServices = listBusinessServices;
        this.listPublicStaff = listPublicStaff;
        this.serviceRepository = serviceRepository;
        this.hoursRepository = hoursRepository;
        this.publicAvailabilityService = publicAvailabilityService;
        this.serviceStaffLookup = serviceStaffLookup;
        this.reviewRepository = reviewRepository;
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
        RatingSummary summary = reviewRepository.findRatingSummaryByBusinessId(b.getId());
        return BusinessDtoMapper.toResponse(b, categories, summary);
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
        Map<UUID, RatingSummary> summaries = reviewRepository.findRatingSummariesForBusiness(b.getId());
        return listPublicStaff.execute(b.getId()).stream()
                .map(s -> StaffMemberDtoMapper.toResponse(s,
                        summaries.getOrDefault(s.getId(), RatingSummary.empty())))
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
        if (service == null || !service.getBusinessId().equals(b.getId())) {
            return List.of();
        }

        List<UUID> eligibleStaff = serviceStaffLookup.eligibleStaffForService(b.getId(), serviceId);
        return publicAvailabilityService.computeSlots(
                b.getId(),
                service.getDuracionMin(),
                staffMemberId,
                date,
                service.getSchedulingMode(),
                eligibleStaff);
    }
}


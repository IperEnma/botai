package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AvailabilitySlotResponse;
import com.botai.application.agenda.dto.BusinessHoursResponse;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.BusinessSummaryResponse;
import com.botai.application.agenda.dto.CategoryResponse;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.StaffMemberResponse;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.mapper.CategoryDtoMapper;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.mapper.StaffMemberDtoMapper;
import com.botai.application.agenda.service.PublicAvailabilityService;
import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.usecase.category.ListPublicCategoriesUseCase;
import com.botai.application.agenda.usecase.search.GetBusinessPublicUseCase;
import com.botai.application.agenda.usecase.search.ListBusinessesByCategoryUseCase;
import com.botai.application.agenda.usecase.search.SearchBusinessesUseCase;
import com.botai.application.agenda.usecase.staff.ListPublicStaffUseCase;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
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
    private final PublicAvailabilityService publicAvailabilityService;
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
                                  PublicAvailabilityService publicAvailabilityService,
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
        this.publicAvailabilityService = publicAvailabilityService;
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

    @GetMapping("/businesses/{businessId}/hours")
    @Operation(summary = "Horarios de atención publicados")
    public List<BusinessHoursResponse> businessHours(@PathVariable("businessId") UUID businessId) {
        if (businessRepository.findById(businessId).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Negocio no encontrado");
        }
        return hoursRepository.findByBusinessId(businessId).stream()
                .map(h -> new BusinessHoursResponse(
                        h.getId(),
                        h.getBusinessId(),
                        h.getDiaSemana(),
                        h.getApertura(),
                        h.getCierre(),
                        h.getApertura2(),
                        h.getCierre2(),
                        h.isCerrado()))
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
        if (service == null || !service.getBusinessId().equals(businessId)) {
            return List.of();
        }

        List<UUID> eligibleStaff = serviceStaffLookup.eligibleStaffForService(businessId, serviceId);
        return publicAvailabilityService.computeSlots(
                businessId,
                service.getDuracionMin(),
                staffMemberId,
                date,
                service.getSchedulingMode(),
                eligibleStaff);
    }
}

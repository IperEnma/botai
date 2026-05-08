package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.AssociateCategoriesRequest;
import com.botai.agenda.application.dto.BusinessResponse;
import com.botai.agenda.application.dto.BusinessSettingsRequest;
import com.botai.agenda.application.dto.BusinessSettingsResponse;
import com.botai.agenda.application.dto.CreateBusinessRequest;
import com.botai.agenda.application.dto.UpdateBusinessRequest;
import com.botai.agenda.application.mapper.BusinessDtoMapper;
import com.botai.agenda.application.usecase.business.AssociateBusinessCategoriesUseCase;
import com.botai.agenda.application.usecase.business.ListBusinessesByTenantUseCase;
import com.botai.agenda.application.usecase.business.RegisterBusinessUseCase;
import com.botai.agenda.application.usecase.business.UpdateBusinessUseCase;
import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.repository.BusinessCategoryRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.botai.agenda.infrastructure.security.AgendaCurrentTenantService;

import java.util.List;
import java.util.UUID;

/** Admin de tenant: CRUD de negocios y asociación de categorías. */
@RestController
@RequestMapping("/api/agenda/me/businesses")
@Tag(name = "Agenda Tenant", description = "Administración de negocios por tenant")
@Validated
public class TenantBusinessController {

    private final RegisterBusinessUseCase registerBusiness;
    private final UpdateBusinessUseCase updateBusiness;
    private final AssociateBusinessCategoriesUseCase associateCategories;
    private final ListBusinessesByTenantUseCase listBusinesses;
    private final BusinessSettingsRepository settingsRepository;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final AgendaCurrentTenantService currentTenant;

    public TenantBusinessController(RegisterBusinessUseCase registerBusiness,
                                    UpdateBusinessUseCase updateBusiness,
                                    AssociateBusinessCategoriesUseCase associateCategories,
                                    ListBusinessesByTenantUseCase listBusinesses,
                                    BusinessSettingsRepository settingsRepository,
                                    BusinessCategoryRepository businessCategoryRepository,
                                    AgendaCurrentTenantService currentTenant) {
        this.registerBusiness = registerBusiness;
        this.updateBusiness = updateBusiness;
        this.associateCategories = associateCategories;
        this.listBusinesses = listBusinesses;
        this.settingsRepository = settingsRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.currentTenant = currentTenant;
    }

    @PostMapping
    @Operation(summary = "Registra un nuevo negocio en el tenant")
    public ResponseEntity<BusinessResponse> create(@Valid @RequestBody CreateBusinessRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var created = registerBusiness.execute(
                tenantId,
                request.nombre(),
                request.descripcion(),
                request.ownerUserId(),
                request.searchTags()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(BusinessDtoMapper.toResponse(created));
    }

    @PutMapping("/{businessId}")
    @Operation(summary = "Actualiza un negocio del tenant")
    public BusinessResponse update(@PathVariable("businessId") UUID businessId,
                                   @Valid @RequestBody UpdateBusinessRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var updated = updateBusiness.execute(
                tenantId,
                businessId,
                request.nombre(),
                request.descripcion(),
                request.searchTags(),
                request.activo(),
                request.logoUrl(),
                request.colorPrimario(),
                request.instagramUrl(),
                request.tiktokUrl(),
                request.facebookUrl(),
                request.colorFondo(),
                request.fontFamily()
        );
        return BusinessDtoMapper.toResponse(updated,
                businessCategoryRepository.findCategorySlugsByBusinessId(updated.getId()));
    }

    @PutMapping("/{businessId}/categories")
    @Operation(summary = "Reemplaza la lista de categorías asociadas al negocio")
    public ResponseEntity<Void> associateCategories(@PathVariable("businessId") UUID businessId,
                                                    @Valid @RequestBody AssociateCategoriesRequest request) {
        String tenantId = currentTenant.requireTenantId();
        associateCategories.execute(tenantId, businessId, request.categoryIds());
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    @Operation(summary = "Lista negocios del tenant")
    public List<BusinessResponse> list() {
        String tenantId = currentTenant.requireTenantId();
        return listBusinesses.listAll(tenantId).stream()
                .map(b -> BusinessDtoMapper.toResponse(b,
                        businessCategoryRepository.findCategorySlugsByBusinessId(b.getId())))
                .toList();
    }

    @GetMapping("/{businessId}")
    @Operation(summary = "Detalle de un negocio del tenant")
    public BusinessResponse detail(@PathVariable("businessId") UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        var business = listBusinesses.findOne(tenantId, businessId);
        return BusinessDtoMapper.toResponse(business,
                businessCategoryRepository.findCategorySlugsByBusinessId(business.getId()));
    }

    @GetMapping("/{businessId}/settings")
    @Operation(summary = "Obtener configuración del negocio (cancelación, loyalty, alertas)")
    public ResponseEntity<BusinessSettingsResponse> getSettings(
            @PathVariable("businessId") UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId); // valida tenant + existencia
        BusinessSettings s = settingsRepository.findByBusinessId(businessId)
                .orElseGet(() -> BusinessSettings.defaults(businessId));
        return ResponseEntity.ok(toSettingsResponse(s));
    }

    @PutMapping("/{businessId}/settings")
    @Operation(summary = "Actualizar configuración del negocio")
    public ResponseEntity<BusinessSettingsResponse> updateSettings(
            @PathVariable("businessId") UUID businessId,
            @Valid @RequestBody BusinessSettingsRequest request) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        BusinessSettings updated = settingsRepository.save(new BusinessSettings(
                businessId,
                request.hoursCancellationLimit(),
                request.loyaltyMinAttendances(),
                request.loyaltyWindowDays(),
                request.expirationAlertDays(),
                request.expirationAlertCredits(),
                request.autoNotifyEnabled()
        ));
        return ResponseEntity.ok(toSettingsResponse(updated));
    }

    private BusinessSettingsResponse toSettingsResponse(BusinessSettings s) {
        return new BusinessSettingsResponse(
                s.getBusinessId(),
                s.getHoursCancellationLimit(),
                s.getLoyaltyMinAttendances(),
                s.getLoyaltyWindowDays(),
                s.getExpirationAlertDays(),
                s.getExpirationAlertCredits(),
                s.isAutoNotifyEnabled()
        );
    }
}

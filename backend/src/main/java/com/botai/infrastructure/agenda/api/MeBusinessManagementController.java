package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AssociateCategoriesRequest;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.BusinessSettingsRequest;
import com.botai.application.agenda.dto.BusinessSettingsResponse;
import com.botai.application.agenda.dto.CreateBusinessRequest;
import com.botai.application.agenda.dto.UpdateBusinessRequest;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.usecase.business.AssociateBusinessCategoriesUseCase;
import com.botai.application.agenda.usecase.business.ListBusinessesByTenantUseCase;
import com.botai.application.agenda.usecase.business.RegisterBusinessUseCase;
import com.botai.application.agenda.usecase.business.UpdateBusinessUseCase;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import com.botai.infrastructure.agenda.sync.AgendaKnowledgeChunkRefresher;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Operaciones sobre negocios del tenant autenticado sin tenantId explícito en la URL.
 *
 * <p>El tenantId se resuelve desde el JWT via {@link AgendaCurrentTenantService}.
 * Esto permite que el frontend llame a {@code /me/businesses/{id}} inmediatamente
 * después del registro, sin necesidad de pasar el tenantId como parámetro.</p>
 */
@RestController
@RequestMapping("/api/agenda/me/businesses")
@Tag(name = "Agenda Me · Businesses", description = "Gestión de negocios del tenant autenticado")
@Validated
public class MeBusinessManagementController {

    private final RegisterBusinessUseCase registerBusiness;
    private final UpdateBusinessUseCase updateBusiness;
    private final ListBusinessesByTenantUseCase listBusinesses;
    private final AssociateBusinessCategoriesUseCase associateCategories;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final AgendaCurrentTenantService currentTenant;
    private final AgendaKnowledgeChunkRefresher knowledgeChunkRefresher;

    public MeBusinessManagementController(RegisterBusinessUseCase registerBusiness,
                                          UpdateBusinessUseCase updateBusiness,
                                          ListBusinessesByTenantUseCase listBusinesses,
                                          AssociateBusinessCategoriesUseCase associateCategories,
                                          BusinessCategoryRepository businessCategoryRepository,
                                          BusinessSettingsRepository settingsRepository,
                                          AgendaCurrentTenantService currentTenant,
                                          AgendaKnowledgeChunkRefresher knowledgeChunkRefresher) {
        this.registerBusiness = registerBusiness;
        this.updateBusiness = updateBusiness;
        this.listBusinesses = listBusinesses;
        this.associateCategories = associateCategories;
        this.businessCategoryRepository = businessCategoryRepository;
        this.settingsRepository = settingsRepository;
        this.currentTenant = currentTenant;
        this.knowledgeChunkRefresher = knowledgeChunkRefresher;
    }

    @GetMapping
    @Operation(summary = "Lista negocios del tenant autenticado")
    public List<BusinessResponse> list() {
        String tenantId = currentTenant.requireTenantId();
        return listBusinesses.listAll(tenantId).stream()
                .map(b -> BusinessDtoMapper.toResponse(b,
                        businessCategoryRepository.findCategorySlugsByBusinessId(b.getId())))
                .toList();
    }

    @GetMapping("/{businessId}")
    @Operation(summary = "Detalle de un negocio del tenant autenticado")
    public BusinessResponse detail(@PathVariable("businessId") UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        var business = listBusinesses.findOne(tenantId, businessId);
        return BusinessDtoMapper.toResponse(business,
                businessCategoryRepository.findCategorySlugsByBusinessId(business.getId()));
    }

    @PostMapping
    @Operation(summary = "Registra un negocio en el tenant autenticado")
    public ResponseEntity<BusinessResponse> create(@Valid @RequestBody CreateBusinessRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var created = registerBusiness.execute(
                tenantId,
                request.nombre(),
                request.descripcion(),
                request.ownerUserId(),
                request.searchTags()
        );
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BusinessDtoMapper.toResponse(created));
    }

    @PutMapping("/{businessId}")
    @Operation(summary = "Actualiza un negocio del tenant autenticado")
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
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return BusinessDtoMapper.toResponse(updated,
                businessCategoryRepository.findCategorySlugsByBusinessId(updated.getId()));
    }

    @PutMapping("/{businessId}/categories")
    @Operation(summary = "Reemplaza las categorías del negocio del tenant autenticado")
    public ResponseEntity<Void> replaceCategories(@PathVariable("businessId") UUID businessId,
                                                  @Valid @RequestBody AssociateCategoriesRequest request) {
        String tenantId = currentTenant.requireTenantId();
        associateCategories.execute(tenantId, businessId, request.categoryIds());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{businessId}/settings")
    @Operation(summary = "Obtener configuración del negocio (cancelación, loyalty, alertas)")
    public ResponseEntity<BusinessSettingsResponse> getSettings(@PathVariable("businessId") UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
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
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
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

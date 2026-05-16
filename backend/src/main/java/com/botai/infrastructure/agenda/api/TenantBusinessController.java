package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AssociateCategoriesRequest;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.BusinessSettingsRequest;
import com.botai.application.agenda.dto.BusinessSettingsResponse;
import com.botai.application.agenda.dto.CreateBusinessRequest;
import com.botai.application.agenda.dto.UpdateBusinessRequest;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.usecase.business.AssociateBusinessCategoriesUseCase;
import com.botai.application.agenda.usecase.business.ListBusinessesByTenantUseCase;
import com.botai.application.agenda.usecase.business.RegisterBusinessUseCase;
import com.botai.application.agenda.usecase.business.UpdateBusinessUseCase;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
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

import com.botai.infrastructure.agenda.sync.AgendaKnowledgeChunkRefresher;

import java.util.List;
import java.util.UUID;

/** Admin de tenant: CRUD de negocios y asociación de categorías. */
@RestController
@RequestMapping("/api/agenda/tenants/{tenantId}/businesses")
@Tag(name = "Agenda Tenant", description = "Administración de negocios por tenant")
@Validated
public class TenantBusinessController {

    private final RegisterBusinessUseCase registerBusiness;
    private final UpdateBusinessUseCase updateBusiness;
    private final AssociateBusinessCategoriesUseCase associateCategories;
    private final ListBusinessesByTenantUseCase listBusinesses;
    private final BusinessSettingsRepository settingsRepository;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final AgendaKnowledgeChunkRefresher knowledgeChunkRefresher;

    public TenantBusinessController(RegisterBusinessUseCase registerBusiness,
                                    UpdateBusinessUseCase updateBusiness,
                                    AssociateBusinessCategoriesUseCase associateCategories,
                                    ListBusinessesByTenantUseCase listBusinesses,
                                    BusinessSettingsRepository settingsRepository,
                                    BusinessCategoryRepository businessCategoryRepository,
                                    AgendaKnowledgeChunkRefresher knowledgeChunkRefresher) {
        this.registerBusiness = registerBusiness;
        this.updateBusiness = updateBusiness;
        this.associateCategories = associateCategories;
        this.listBusinesses = listBusinesses;
        this.settingsRepository = settingsRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.knowledgeChunkRefresher = knowledgeChunkRefresher;
    }

    @PostMapping
    @Operation(summary = "Registra un nuevo negocio en el tenant")
    public ResponseEntity<BusinessResponse> create(@PathVariable String tenantId,
                                                   @Valid @RequestBody CreateBusinessRequest request) {
        var created = registerBusiness.execute(
                tenantId,
                request.nombre(),
                request.descripcion(),
                request.ownerUserId(),
                request.searchTags()
        );
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.status(HttpStatus.CREATED).body(BusinessDtoMapper.toResponse(created));
    }

    @PutMapping("/{businessId}")
    @Operation(summary = "Actualiza un negocio del tenant")
    public BusinessResponse update(@PathVariable String tenantId,
                                   @PathVariable("businessId") UUID businessId,
                                   @Valid @RequestBody UpdateBusinessRequest request) {
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
    @Operation(summary = "Reemplaza la lista de categorías asociadas al negocio")
    public ResponseEntity<Void> associateCategories(@PathVariable String tenantId,
                                                    @PathVariable("businessId") UUID businessId,
                                                    @Valid @RequestBody AssociateCategoriesRequest request) {
        associateCategories.execute(tenantId, businessId, request.categoryIds());
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    @Operation(summary = "Lista negocios del tenant")
    public List<BusinessResponse> list(@PathVariable String tenantId) {
        return listBusinesses.listAll(tenantId).stream()
                .map(b -> BusinessDtoMapper.toResponse(b,
                        businessCategoryRepository.findCategorySlugsByBusinessId(b.getId())))
                .toList();
    }

    @GetMapping("/{businessId}")
    @Operation(summary = "Detalle de un negocio del tenant")
    public BusinessResponse detail(@PathVariable String tenantId,
                                   @PathVariable("businessId") UUID businessId) {
        var business = listBusinesses.findOne(tenantId, businessId);
        return BusinessDtoMapper.toResponse(business,
                businessCategoryRepository.findCategorySlugsByBusinessId(business.getId()));
    }

    @GetMapping("/{businessId}/settings")
    @Operation(summary = "Obtener configuración del negocio (cancelación, loyalty, alertas)")
    public ResponseEntity<BusinessSettingsResponse> getSettings(
            @PathVariable String tenantId,
            @PathVariable("businessId") UUID businessId) {
        listBusinesses.findOne(tenantId, businessId); // valida tenant + existencia
        BusinessSettings s = settingsRepository.findByBusinessId(businessId)
                .orElseGet(() -> BusinessSettings.defaults(businessId));
        return ResponseEntity.ok(toSettingsResponse(s));
    }

    @PutMapping("/{businessId}/settings")
    @Operation(summary = "Actualizar configuración del negocio")
    public ResponseEntity<BusinessSettingsResponse> updateSettings(
            @PathVariable String tenantId,
            @PathVariable("businessId") UUID businessId,
            @Valid @RequestBody BusinessSettingsRequest request) {
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

package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AssociateCategoriesRequest;
import com.botai.application.agenda.dto.BusinessResponse;
import com.botai.application.agenda.dto.UpdateBusinessRequest;
import com.botai.application.agenda.mapper.BusinessDtoMapper;
import com.botai.application.agenda.usecase.business.AssociateBusinessCategoriesUseCase;
import com.botai.application.agenda.usecase.business.UpdateBusinessUseCase;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import com.botai.infrastructure.agenda.sync.AgendaKnowledgeChunkRefresher;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

    private final UpdateBusinessUseCase updateBusiness;
    private final AssociateBusinessCategoriesUseCase associateCategories;
    private final BusinessCategoryRepository businessCategoryRepository;
    private final AgendaCurrentTenantService currentTenant;
    private final AgendaKnowledgeChunkRefresher knowledgeChunkRefresher;

    public MeBusinessManagementController(UpdateBusinessUseCase updateBusiness,
                                          AssociateBusinessCategoriesUseCase associateCategories,
                                          BusinessCategoryRepository businessCategoryRepository,
                                          AgendaCurrentTenantService currentTenant,
                                          AgendaKnowledgeChunkRefresher knowledgeChunkRefresher) {
        this.updateBusiness = updateBusiness;
        this.associateCategories = associateCategories;
        this.businessCategoryRepository = businessCategoryRepository;
        this.currentTenant = currentTenant;
        this.knowledgeChunkRefresher = knowledgeChunkRefresher;
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
}

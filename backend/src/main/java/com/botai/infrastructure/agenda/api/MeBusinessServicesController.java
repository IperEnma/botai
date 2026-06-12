package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.CreateServiceRequest;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.UpdateServiceRequest;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.service.ServiceStaffLookup;
import com.botai.application.agenda.usecase.service.CreateServiceUseCase;
import com.botai.application.agenda.usecase.service.DeleteServiceUseCase;
import com.botai.application.agenda.usecase.service.UpdateServiceUseCase;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import com.botai.infrastructure.agenda.sync.AgendaKnowledgeChunkRefresher;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/services")
@Tag(name = "Agenda Me · Services", description = "Servicios del negocio del tenant autenticado")
@Validated
public class MeBusinessServicesController {

    private final CreateServiceUseCase createService;
    private final UpdateServiceUseCase updateService;
    private final DeleteServiceUseCase deleteService;
    private final ListBusinessServicesUseCase listServices;
    private final AgendaCurrentTenantService currentTenant;
    private final AgendaKnowledgeChunkRefresher knowledgeChunkRefresher;
    private final ServiceStaffLookup serviceStaffLookup;

    public MeBusinessServicesController(CreateServiceUseCase createService,
                                        UpdateServiceUseCase updateService,
                                        DeleteServiceUseCase deleteService,
                                        ListBusinessServicesUseCase listServices,
                                        AgendaCurrentTenantService currentTenant,
                                        AgendaKnowledgeChunkRefresher knowledgeChunkRefresher,
                                        ServiceStaffLookup serviceStaffLookup) {
        this.createService = createService;
        this.updateService = updateService;
        this.deleteService = deleteService;
        this.listServices = listServices;
        this.currentTenant = currentTenant;
        this.knowledgeChunkRefresher = knowledgeChunkRefresher;
        this.serviceStaffLookup = serviceStaffLookup;
    }

    @GetMapping
    @Operation(summary = "Listar servicios del negocio del tenant autenticado")
    @PreAuthorize("@authz.canViewBusiness(#businessId)")
    public ResponseEntity<List<ServiceResponse>> list(
            @PathVariable UUID businessId,
            @RequestParam(value = "soloActivos", required = false, defaultValue = "false") boolean soloActivos) {
        String tenantId = currentTenant.requireTenantId();
        Map<UUID, List<UUID>> staffByService = serviceStaffLookup.staffIdsByServiceId(businessId);
        List<ServiceResponse> result = listServices.execute(tenantId, businessId, soloActivos)
                .stream()
                .map(s -> ServiceDtoMapper.toResponse(
                        s, staffByService.getOrDefault(s.getId(), List.of())))
                .toList();
        return ResponseEntity.ok(result);
    }

    @PostMapping
    @Operation(summary = "Crear un servicio para el negocio del tenant autenticado")
    @PreAuthorize("@authz.canManageBusiness(#businessId)")
    public ResponseEntity<ServiceResponse> create(
            @PathVariable UUID businessId,
            @Valid @RequestBody CreateServiceRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var created = createService.execute(tenantId, businessId,
                request.nombre(), request.descripcion(),
                request.duracionMin(), request.precio(),
                ServiceSchedulingMode.fromString(request.schedulingModeOrDefault()),
                request.staffMemberIds());
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        List<UUID> staffIds = serviceStaffLookup.staffIdsByServiceId(businessId)
                .getOrDefault(created.getId(), List.of());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ServiceDtoMapper.toResponse(created, staffIds));
    }

    @PutMapping("/{serviceId}")
    @Operation(summary = "Actualizar un servicio del negocio del tenant autenticado")
    @PreAuthorize("@authz.canManageBusiness(#businessId)")
    public ResponseEntity<ServiceResponse> update(
            @PathVariable UUID businessId,
            @PathVariable UUID serviceId,
            @Valid @RequestBody UpdateServiceRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var updated = updateService.execute(tenantId, businessId, serviceId,
                request.nombre(), request.descripcion(),
                request.duracionMin(), request.precio(), request.activo(),
                ServiceSchedulingMode.fromString(request.schedulingModeOrDefault()),
                request.staffMemberIds());
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        List<UUID> staffIds = serviceStaffLookup.staffIdsByServiceId(businessId)
                .getOrDefault(updated.getId(), List.of());
        return ResponseEntity.ok(ServiceDtoMapper.toResponse(updated, staffIds));
    }

    @DeleteMapping("/{serviceId}")
    @Operation(summary = "Eliminar (soft-delete) un servicio del negocio del tenant autenticado")
    @PreAuthorize("@authz.canManageBusiness(#businessId)")
    public ResponseEntity<Void> delete(
            @PathVariable UUID businessId,
            @PathVariable UUID serviceId) {
        String tenantId = currentTenant.requireTenantId();
        deleteService.execute(tenantId, businessId, serviceId);
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.noContent().build();
    }
}

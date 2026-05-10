package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.CreateServiceRequest;
import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.application.agenda.dto.UpdateServiceRequest;
import com.botai.application.agenda.mapper.ServiceDtoMapper;
import com.botai.application.agenda.usecase.business.ListBusinessServicesUseCase;
import com.botai.application.agenda.usecase.service.CreateServiceUseCase;
import com.botai.application.agenda.usecase.service.DeleteServiceUseCase;
import com.botai.application.agenda.usecase.service.UpdateServiceUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
import java.util.UUID;
import com.botai.infrastructure.agenda.sync.AgendaKnowledgeChunkRefresher;

@RestController
@RequestMapping("/api/agenda/tenants/{tenantId}/businesses/{businessId}/services")
@Tag(name = "Agenda Tenant · Services", description = "CRUD de servicios por negocio")
@Validated
public class TenantServicesController {

    private final CreateServiceUseCase createService;
    private final UpdateServiceUseCase updateService;
    private final DeleteServiceUseCase deleteService;
    private final ListBusinessServicesUseCase listServices;
    private final AgendaKnowledgeChunkRefresher knowledgeChunkRefresher;

    public TenantServicesController(CreateServiceUseCase createService,
                                    UpdateServiceUseCase updateService,
                                    DeleteServiceUseCase deleteService,
                                    ListBusinessServicesUseCase listServices,
                                    AgendaKnowledgeChunkRefresher knowledgeChunkRefresher) {
        this.createService = createService;
        this.updateService = updateService;
        this.deleteService = deleteService;
        this.listServices = listServices;
        this.knowledgeChunkRefresher = knowledgeChunkRefresher;
    }

    @GetMapping
    @Operation(summary = "Listar servicios del negocio (activos y todos)")
    public ResponseEntity<List<ServiceResponse>> list(
            @PathVariable String tenantId,
            @PathVariable UUID businessId,
            @RequestParam(value = "soloActivos", required = false, defaultValue = "false") boolean soloActivos) {
        List<ServiceResponse> result = listServices.execute(tenantId, businessId, soloActivos)
                .stream().map(ServiceDtoMapper::toResponse).toList();
        return ResponseEntity.ok(result);
    }

    @PostMapping
    @Operation(summary = "Crear un servicio para el negocio")
    public ResponseEntity<ServiceResponse> create(
            @PathVariable String tenantId,
            @PathVariable UUID businessId,
            @Valid @RequestBody CreateServiceRequest request) {
        var created = createService.execute(tenantId, businessId,
                request.nombre(), request.descripcion(),
                request.duracionMin(), request.precio());
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ServiceDtoMapper.toResponse(created));
    }

    @PutMapping("/{serviceId}")
    @Operation(summary = "Actualizar un servicio")
    public ResponseEntity<ServiceResponse> update(
            @PathVariable String tenantId,
            @PathVariable UUID businessId,
            @PathVariable UUID serviceId,
            @Valid @RequestBody UpdateServiceRequest request) {
        var updated = updateService.execute(tenantId, businessId, serviceId,
                request.nombre(), request.descripcion(),
                request.duracionMin(), request.precio(), request.activo());
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.ok(ServiceDtoMapper.toResponse(updated));
    }

    @DeleteMapping("/{serviceId}")
    @Operation(summary = "Eliminar (soft-delete) un servicio")
    public ResponseEntity<Void> delete(
            @PathVariable String tenantId,
            @PathVariable UUID businessId,
            @PathVariable UUID serviceId) {
        deleteService.execute(tenantId, businessId, serviceId);
        knowledgeChunkRefresher.refreshAfterCatalogChange(tenantId);
        return ResponseEntity.noContent().build();
    }
}

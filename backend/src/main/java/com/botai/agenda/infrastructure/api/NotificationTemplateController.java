package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.NotificationTemplateRequest;
import com.botai.agenda.application.dto.NotificationTemplateResponse;
import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.NotificationTemplate;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.NotificationTemplateRepository;
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
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;
import com.botai.agenda.infrastructure.security.AgendaCurrentTenantService;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/notification-templates")
@Tag(name = "Agenda Notifications · Templates", description = "Plantillas de notificación editables por el negocio")
@Validated
public class NotificationTemplateController {

    private final BusinessRepository businessRepository;
    private final NotificationTemplateRepository templateRepository;
    private final AgendaCurrentTenantService currentTenant;

    public NotificationTemplateController(BusinessRepository businessRepository,
                                          NotificationTemplateRepository templateRepository,
                                          AgendaCurrentTenantService currentTenant) {
        this.businessRepository = businessRepository;
        this.templateRepository = templateRepository;
        this.currentTenant = currentTenant;
    }

    @GetMapping
    @Operation(summary = "Listar plantillas de notificación del negocio")
    public ResponseEntity<List<NotificationTemplateResponse>> list(
            @PathVariable UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        validateBusiness(tenantId, businessId);
        List<NotificationTemplateResponse> result = templateRepository
                .findAllByBusinessId(businessId)
                .stream().map(this::toResponse).toList();
        return ResponseEntity.ok(result);
    }

    @PostMapping
    @Operation(summary = "Crear una plantilla de notificación")
    public ResponseEntity<NotificationTemplateResponse> create(
            @PathVariable UUID businessId,
            @Valid @RequestBody NotificationTemplateRequest request) {
        String tenantId = currentTenant.requireTenantId();
        validateBusiness(tenantId, businessId);
        NotificationTemplate template = new NotificationTemplate(
                null, businessId, request.codigo(), request.canal(),
                request.titulo(), request.cuerpo(), null, null);
        NotificationTemplate saved = templateRepository.save(template);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @PutMapping("/{templateId}")
    @Operation(summary = "Actualizar una plantilla de notificación")
    public ResponseEntity<NotificationTemplateResponse> update(
            @PathVariable UUID businessId,
            @PathVariable UUID templateId,
            @Valid @RequestBody NotificationTemplateRequest request) {
        String tenantId = currentTenant.requireTenantId();
        validateBusiness(tenantId, businessId);
        NotificationTemplate existing = templateRepository.findById(templateId)
                .filter(t -> t.getBusinessId().equals(businessId))
                .orElseThrow(() -> new IllegalArgumentException("Plantilla no encontrada: " + templateId));
        NotificationTemplate updated = new NotificationTemplate(
                existing.getId(), businessId, request.codigo(), request.canal(),
                request.titulo(), request.cuerpo(),
                existing.getCreatedAt(), existing.getUpdatedAt());
        return ResponseEntity.ok(toResponse(templateRepository.save(updated)));
    }

    @DeleteMapping("/{templateId}")
    @Operation(summary = "Eliminar una plantilla de notificación")
    public ResponseEntity<Void> delete(
            @PathVariable UUID businessId,
            @PathVariable UUID templateId) {
        String tenantId = currentTenant.requireTenantId();
        validateBusiness(tenantId, businessId);
        templateRepository.findById(templateId)
                .filter(t -> t.getBusinessId().equals(businessId))
                .orElseThrow(() -> new IllegalArgumentException("Plantilla no encontrada: " + templateId));
        templateRepository.deleteById(templateId);
        return ResponseEntity.noContent().build();
    }

    private void validateBusiness(String tenantId, UUID businessId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }

    private NotificationTemplateResponse toResponse(NotificationTemplate t) {
        return new NotificationTemplateResponse(
                t.getId(), t.getBusinessId(), t.getCodigo(), t.getCanal(),
                t.getTitulo(), t.getCuerpo(), t.getCreatedAt(), t.getUpdatedAt());
    }
}

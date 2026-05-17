package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.NotificationTemplateRequest;
import com.botai.application.agenda.dto.NotificationTemplateResponse;
import com.botai.domain.agenda.model.NotificationTemplate;
import com.botai.domain.agenda.repository.NotificationTemplateRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
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

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/notification-templates")
@Tag(name = "Agenda Notifications · Templates", description = "Plantillas de notificación editables por el negocio")
@Validated
public class NotificationTemplateController {

    private final NotificationTemplateRepository templateRepository;
    private final AgendaCurrentTenantService currentTenant;

    public NotificationTemplateController(NotificationTemplateRepository templateRepository,
                                          AgendaCurrentTenantService currentTenant) {
        this.templateRepository = templateRepository;
        this.currentTenant = currentTenant;
    }

    @GetMapping
    @Operation(summary = "Listar plantillas de notificación del negocio")
    public ResponseEntity<List<NotificationTemplateResponse>> list(@PathVariable UUID businessId) {
        validateBusiness(businessId);
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
        validateBusiness(businessId);
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
        validateBusiness(businessId);
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
        validateBusiness(businessId);
        templateRepository.findById(templateId)
                .filter(t -> t.getBusinessId().equals(businessId))
                .orElseThrow(() -> new IllegalArgumentException("Plantilla no encontrada: " + templateId));
        templateRepository.deleteById(templateId);
        return ResponseEntity.noContent().build();
    }

    private void validateBusiness(UUID businessId) {
        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);
    }

    private NotificationTemplateResponse toResponse(NotificationTemplate t) {
        return new NotificationTemplateResponse(
                t.getId(), t.getBusinessId(), t.getCodigo(), t.getCanal(),
                t.getTitulo(), t.getCuerpo(), t.getCreatedAt(), t.getUpdatedAt());
    }
}

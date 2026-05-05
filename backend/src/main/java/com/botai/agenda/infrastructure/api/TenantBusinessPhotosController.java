package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.AddBusinessPhotoRequest;
import com.botai.agenda.application.dto.BusinessPhotoResponse;
import com.botai.agenda.application.usecase.business.BusinessPhotosUseCase;
import com.botai.agenda.domain.model.BusinessPhoto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/tenants/{tenantId}/businesses/{businessId}/photos")
@Tag(name = "Agenda Tenant", description = "Galería de fotos del negocio")
public class TenantBusinessPhotosController {

    private final BusinessPhotosUseCase photosUseCase;

    public TenantBusinessPhotosController(BusinessPhotosUseCase photosUseCase) {
        this.photosUseCase = photosUseCase;
    }

    @GetMapping
    @Operation(summary = "Lista las fotos del negocio (máx 10)")
    public List<BusinessPhotoResponse> list(@PathVariable String tenantId,
                                            @PathVariable UUID businessId) {
        return photosUseCase.list(tenantId, businessId).stream()
                .map(this::toResponse)
                .toList();
    }

    @PostMapping
    @Operation(summary = "Agrega una foto al negocio (máx 10)")
    public ResponseEntity<BusinessPhotoResponse> add(@PathVariable String tenantId,
                                                     @PathVariable UUID businessId,
                                                     @Valid @RequestBody AddBusinessPhotoRequest request) {
        try {
            BusinessPhoto saved = photosUseCase.add(tenantId, businessId, request.url());
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
        } catch (IllegalStateException e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
        }
    }

    @DeleteMapping("/{photoId}")
    @Operation(summary = "Elimina una foto del negocio")
    public ResponseEntity<Void> delete(@PathVariable String tenantId,
                                       @PathVariable UUID businessId,
                                       @PathVariable UUID photoId) {
        photosUseCase.delete(tenantId, businessId, photoId);
        return ResponseEntity.noContent().build();
    }

    private BusinessPhotoResponse toResponse(BusinessPhoto p) {
        return new BusinessPhotoResponse(p.getId(), p.getBusinessId(), p.getUrl(), p.getOrden(), p.getCreatedAt());
    }
}

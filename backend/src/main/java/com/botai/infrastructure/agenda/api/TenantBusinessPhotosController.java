package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.AddBusinessPhotoRequest;
import com.botai.application.agenda.dto.BusinessPhotoResponse;
import com.botai.application.agenda.support.AgendaMediaUploadSupport;
import com.botai.application.agenda.usecase.business.BusinessPhotosUseCase;
import com.botai.domain.agenda.model.BusinessPhoto;
import com.botai.domain.agenda.service.AgendaMediaStoragePort;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/photos")
@Tag(name = "Agenda Tenant", description = "Galería de fotos del negocio")
public class TenantBusinessPhotosController {

    private final BusinessPhotosUseCase photosUseCase;
    private final AgendaCurrentTenantService currentTenant;
    private final AgendaMediaStoragePort mediaStorage;

    public TenantBusinessPhotosController(BusinessPhotosUseCase photosUseCase,
                                         AgendaCurrentTenantService currentTenant,
                                         AgendaMediaStoragePort mediaStorage) {
        this.photosUseCase = photosUseCase;
        this.currentTenant = currentTenant;
        this.mediaStorage = mediaStorage;
    }

    @GetMapping
    @Operation(summary = "Lista las fotos del negocio (máx 10)")
    public List<BusinessPhotoResponse> list(@PathVariable UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        return photosUseCase.list(tenantId, businessId).stream()
                .map(this::toResponse)
                .toList();
    }

    @PostMapping
    @Operation(summary = "Agrega una foto al negocio (máx 10)")
    public ResponseEntity<BusinessPhotoResponse> add(@PathVariable UUID businessId,
                                                     @Valid @RequestBody AddBusinessPhotoRequest request) {
        String tenantId = currentTenant.requireTenantId();
        try {
            BusinessPhoto saved = photosUseCase.add(tenantId, businessId, request.url());
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
        } catch (IllegalStateException e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
        }
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Sube una foto de trabajo y la agrega a la galería (máx 10)")
    public ResponseEntity<BusinessPhotoResponse> upload(
            @PathVariable UUID businessId,
            @RequestParam("file") MultipartFile file) throws IOException {
        String tenantId = currentTenant.requireTenantId();
        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);

        String ext = AgendaMediaUploadSupport.fileExtension(file.getOriginalFilename());
        String fileName = UUID.randomUUID() + "." + ext;
        String storageKey = "businesses/" + businessId + "/works/" + fileName;
        String contentType = AgendaMediaUploadSupport.resolveContentType(file, storageKey);

        String url = mediaStorage.store(storageKey, file.getBytes(), contentType);
        try {
            BusinessPhoto saved = photosUseCase.add(tenantId, businessId, url);
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
        } catch (IllegalStateException e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
        }
    }

    @DeleteMapping("/{photoId}")
    @Operation(summary = "Elimina una foto del negocio")
    public ResponseEntity<Void> delete(@PathVariable UUID businessId,
                                       @PathVariable UUID photoId) {
        String tenantId = currentTenant.requireTenantId();
        photosUseCase.delete(tenantId, businessId, photoId);
        return ResponseEntity.noContent().build();
    }

    private BusinessPhotoResponse toResponse(BusinessPhoto p) {
        return new BusinessPhotoResponse(p.getId(), p.getBusinessId(), p.getUrl(), p.getOrden(), p.getCreatedAt());
    }
}

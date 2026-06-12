package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.support.AgendaMediaUploadSupport;
import com.botai.application.agenda.usecase.business.UpdateBusinessUseCase;
import com.botai.domain.agenda.service.AgendaMediaStoragePort;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}")
@Tag(name = "Agenda Tenant", description = "Administración de negocios por tenant")
@PreAuthorize("@authz.canManageBusiness(#businessId)")
public class BusinessAvatarController {

    private final AgendaMediaStoragePort mediaStorage;
    private final AgendaCurrentTenantService currentTenant;
    private final UpdateBusinessUseCase updateBusiness;

    public BusinessAvatarController(AgendaMediaStoragePort mediaStorage,
                                    AgendaCurrentTenantService currentTenant,
                                    UpdateBusinessUseCase updateBusiness) {
        this.mediaStorage = mediaStorage;
        this.currentTenant = currentTenant;
        this.updateBusiness = updateBusiness;
    }

    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Sube la imagen de avatar del negocio")
    public ResponseEntity<Map<String, String>> uploadAvatar(
            @PathVariable UUID businessId,
            @RequestParam("file") MultipartFile file) throws IOException {

        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);
        String tenantId = currentTenant.requireTenantId();

        String ext = AgendaMediaUploadSupport.fileExtension(file.getOriginalFilename());
        String fileName = UUID.randomUUID() + "." + ext;
        String storageKey = "businesses/" + businessId + "/" + fileName;
        String contentType = AgendaMediaUploadSupport.resolveContentType(file, storageKey);

        String url = mediaStorage.store(storageKey, file.getBytes(), contentType);
        updateBusiness.execute(
                tenantId,
                businessId,
                null, null, null, null,
                url,
                null, null, null, null, null, null, null,
                null,
                null
        );
        return ResponseEntity.ok(Map.of("url", url));
    }
}

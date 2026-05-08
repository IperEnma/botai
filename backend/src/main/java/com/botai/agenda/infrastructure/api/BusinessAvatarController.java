package com.botai.agenda.infrastructure.api;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.infrastructure.config.AgendaUploadProperties;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.botai.agenda.infrastructure.security.AgendaCurrentTenantService;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}")
@Tag(name = "Agenda Tenant", description = "Administración de negocios por tenant")
public class BusinessAvatarController {

    private final BusinessRepository businessRepository;
    private final AgendaUploadProperties uploadProps;
    private final AgendaCurrentTenantService currentTenant;

    public BusinessAvatarController(BusinessRepository businessRepository,
                                    AgendaUploadProperties uploadProps,
                                    AgendaCurrentTenantService currentTenant) {
        this.businessRepository = businessRepository;
        this.uploadProps = uploadProps;
        this.currentTenant = currentTenant;
    }

    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Sube la imagen de avatar del negocio al filesystem")
    public ResponseEntity<Map<String, String>> uploadAvatar(
            @PathVariable UUID businessId,
            @RequestParam("file") MultipartFile file) throws IOException {

        String tenantId = currentTenant.requireTenantId();
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.') + 1).toLowerCase()
                : "jpg";

        String fileName = UUID.randomUUID() + "." + ext;
        Path dir = Paths.get(uploadProps.getDir(), "businesses", businessId.toString());
        Files.createDirectories(dir);
        Files.copy(file.getInputStream(), dir.resolve(fileName), StandardCopyOption.REPLACE_EXISTING);

        String url = uploadProps.getBaseUrl() + "/businesses/" + businessId + "/" + fileName;
        return ResponseEntity.ok(Map.of("url", url));
    }
}

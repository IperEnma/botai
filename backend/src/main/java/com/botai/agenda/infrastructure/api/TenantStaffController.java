package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.CreateStaffMemberRequest;
import com.botai.agenda.application.dto.StaffMemberResponse;
import com.botai.agenda.application.dto.UpdateStaffMemberRequest;
import com.botai.agenda.application.mapper.StaffMemberDtoMapper;
import com.botai.agenda.application.usecase.staff.ManageStaffUseCase;
import com.botai.agenda.domain.exception.StaffMemberNotFoundException;
import com.botai.agenda.domain.repository.StaffMemberRepository;
import com.botai.agenda.infrastructure.config.AgendaUploadProperties;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.botai.agenda.application.usecase.business.ListBusinessesByTenantUseCase;
import com.botai.agenda.infrastructure.security.AgendaCurrentTenantService;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/staff")
@Tag(name = "Agenda Tenant", description = "Gestión de miembros del equipo de trabajo")
public class TenantStaffController {

    private final ManageStaffUseCase manageStaff;
    private final StaffMemberRepository staffRepository;
    private final AgendaUploadProperties uploadProps;
    private final AgendaCurrentTenantService currentTenant;
    private final ListBusinessesByTenantUseCase listBusinesses;

    public TenantStaffController(ManageStaffUseCase manageStaff,
                                  StaffMemberRepository staffRepository,
                                  AgendaUploadProperties uploadProps,
                                  AgendaCurrentTenantService currentTenant,
                                  ListBusinessesByTenantUseCase listBusinesses) {
        this.manageStaff = manageStaff;
        this.staffRepository = staffRepository;
        this.uploadProps = uploadProps;
        this.currentTenant = currentTenant;
        this.listBusinesses = listBusinesses;
    }

    @GetMapping
    @Operation(summary = "Listar todos los miembros del equipo (incluye inactivos)")
    public List<StaffMemberResponse> list(@PathVariable UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        return manageStaff.list(tenantId, businessId).stream()
                .map(StaffMemberDtoMapper::toResponse)
                .toList();
    }

    @PostMapping
    @Operation(summary = "Agregar un miembro al equipo")
    public ResponseEntity<StaffMemberResponse> create(@PathVariable UUID businessId,
                                                       @Valid @RequestBody CreateStaffMemberRequest request) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        var saved = manageStaff.create(tenantId, businessId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(StaffMemberDtoMapper.toResponse(saved));
    }

    @PutMapping("/{staffId}")
    @Operation(summary = "Actualizar datos de un miembro del equipo")
    public StaffMemberResponse update(@PathVariable UUID businessId,
                                       @PathVariable UUID staffId,
                                       @Valid @RequestBody UpdateStaffMemberRequest request) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        var updated = manageStaff.update(tenantId, businessId, staffId, request);
        return StaffMemberDtoMapper.toResponse(updated);
    }

    @DeleteMapping("/{staffId}")
    @Operation(summary = "Desactivar (soft-delete) un miembro del equipo")
    public ResponseEntity<Void> deactivate(@PathVariable UUID businessId,
                                            @PathVariable UUID staffId) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        manageStaff.deactivate(tenantId, businessId, staffId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/{staffId}/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Sube la imagen de avatar de un miembro del equipo")
    public ResponseEntity<Map<String, String>> uploadAvatar(
            @PathVariable UUID businessId,
            @PathVariable UUID staffId,
            @RequestParam("file") MultipartFile file) throws IOException {

        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);

        if (!staffRepository.existsByIdAndBusinessId(staffId, businessId)) {
            throw new StaffMemberNotFoundException(staffId);
        }

        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.') + 1).toLowerCase()
                : "jpg";

        String fileName = UUID.randomUUID() + "." + ext;
        Path dir = Paths.get(uploadProps.getDir(), "staff", staffId.toString());
        Files.createDirectories(dir);
        Files.copy(file.getInputStream(), dir.resolve(fileName), StandardCopyOption.REPLACE_EXISTING);

        String url = uploadProps.getBaseUrl() + "/staff/" + staffId + "/" + fileName;
        return ResponseEntity.ok(Map.of("url", url));
    }
}

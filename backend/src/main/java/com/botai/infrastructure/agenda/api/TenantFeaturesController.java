package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.TenantFeaturesResponse;
import com.botai.application.agenda.dto.UpdateTenantFeaturesRequest;
import com.botai.application.agenda.mapper.TenantConfigDtoMapper;
import com.botai.application.agenda.usecase.feature.GetTenantFeaturesUseCase;
import com.botai.application.agenda.usecase.feature.UpdateTenantFeaturesUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;

/** Endpoints de lectura/actualización de flags por tenant. */
@RestController
@RequestMapping("/api/agenda/me/features")
@Tag(name = "Agenda Tenant Features", description = "Flags por tenant del módulo AGENDA")
@Validated
public class TenantFeaturesController {

    private final GetTenantFeaturesUseCase getFeatures;
    private final UpdateTenantFeaturesUseCase updateFeatures;
    private final AgendaCurrentTenantService currentTenant;

    public TenantFeaturesController(GetTenantFeaturesUseCase getFeatures,
                                    UpdateTenantFeaturesUseCase updateFeatures,
                                    AgendaCurrentTenantService currentTenant) {
        this.getFeatures = getFeatures;
        this.updateFeatures = updateFeatures;
        this.currentTenant = currentTenant;
    }

    @GetMapping
    @Operation(summary = "Obtiene los flags del tenant")
    public TenantFeaturesResponse get() {
        String tenantId = currentTenant.requireTenantId();
        return TenantConfigDtoMapper.toResponse(getFeatures.execute(tenantId));
    }

    @PutMapping
    @Operation(summary = "Actualiza (patch) los flags del tenant")
    public TenantFeaturesResponse update(@Valid @RequestBody UpdateTenantFeaturesRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var updated = updateFeatures.execute(
                tenantId,
                request.agendaEnabled(),
                request.publicSearchEnabled(),
                request.loyaltyEngineEnabled(),
                request.autoNotifications()
        );
        return TenantConfigDtoMapper.toResponse(updated);
    }
}

package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.TenantFeaturesResponse;
import com.botai.agenda.application.dto.UpdateTenantFeaturesRequest;
import com.botai.agenda.application.mapper.TenantConfigDtoMapper;
import com.botai.agenda.application.usecase.feature.GetTenantFeaturesUseCase;
import com.botai.agenda.application.usecase.feature.UpdateTenantFeaturesUseCase;
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

/** Endpoints de lectura/actualización de flags por tenant. */
@RestController
@RequestMapping("/api/agenda/tenants/{tenantId}/features")
@Tag(name = "Agenda Tenant Features", description = "Flags por tenant del módulo AGENDA")
@Validated
public class TenantFeaturesController {

    private final GetTenantFeaturesUseCase getFeatures;
    private final UpdateTenantFeaturesUseCase updateFeatures;

    public TenantFeaturesController(GetTenantFeaturesUseCase getFeatures,
                                    UpdateTenantFeaturesUseCase updateFeatures) {
        this.getFeatures = getFeatures;
        this.updateFeatures = updateFeatures;
    }

    @GetMapping
    @Operation(summary = "Obtiene los flags del tenant")
    public TenantFeaturesResponse get(@PathVariable("tenantId") String tenantId) {
        return TenantConfigDtoMapper.toResponse(getFeatures.execute(tenantId));
    }

    @PutMapping
    @Operation(summary = "Actualiza (patch) los flags del tenant")
    public TenantFeaturesResponse update(@PathVariable("tenantId") String tenantId,
                                         @Valid @RequestBody UpdateTenantFeaturesRequest request) {
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

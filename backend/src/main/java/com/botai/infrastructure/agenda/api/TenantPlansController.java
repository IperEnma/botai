package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.CreatePlanRequest;
import com.botai.application.agenda.dto.PlanResponse;
import com.botai.application.agenda.dto.UpdatePlanRequest;
import com.botai.application.agenda.mapper.PlanDtoMapper;
import com.botai.application.agenda.usecase.plan.CreatePlanUseCase;
import com.botai.application.agenda.usecase.plan.DeletePlanUseCase;
import com.botai.application.agenda.usecase.plan.GetPlanUseCase;
import com.botai.application.agenda.usecase.plan.ListPlansByBusinessUseCase;
import com.botai.application.agenda.usecase.plan.UpdatePlanUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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

import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;

import java.util.List;
import java.util.UUID;

/**
 * CRUD de planes del negocio. Vive en el mismo namespace que los demás recursos
 * del admin de tenant ({@code /api/agenda/me/businesses/{businessId}/...}) y queda
 * protegido por {@code AgendaFeatureGuard} (404 si {@code AGENDA_ENABLED=false}).
 *
 * <p>{@code DELETE} hace baja lógica (activo=false) porque las suscripciones
 * futuras mantienen FK {@code RESTRICT} al plan; ver {@code DeletePlanUseCase}.</p>
 */
@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/plans")
@Tag(name = "Agenda Tenant · Plans", description = "CRUD de planes por negocio")
@Validated
public class TenantPlansController {

    private final CreatePlanUseCase createPlan;
    private final UpdatePlanUseCase updatePlan;
    private final DeletePlanUseCase deletePlan;
    private final ListPlansByBusinessUseCase listPlans;
    private final GetPlanUseCase getPlan;
    private final AgendaCurrentTenantService currentTenant;

    public TenantPlansController(CreatePlanUseCase createPlan,
                                 UpdatePlanUseCase updatePlan,
                                 DeletePlanUseCase deletePlan,
                                 ListPlansByBusinessUseCase listPlans,
                                 GetPlanUseCase getPlan,
                                 AgendaCurrentTenantService currentTenant) {
        this.createPlan = createPlan;
        this.updatePlan = updatePlan;
        this.deletePlan = deletePlan;
        this.listPlans = listPlans;
        this.getPlan = getPlan;
        this.currentTenant = currentTenant;
    }

    @PostMapping
    @Operation(summary = "Crea un plan para el negocio")
    public ResponseEntity<PlanResponse> create(@PathVariable("businessId") UUID businessId,
                                               @Valid @RequestBody CreatePlanRequest request) {
        String tenantId = currentTenant.requireTenantId();
        boolean activo = request.activo() == null || request.activo();
        var created = createPlan.execute(
                tenantId, businessId,
                request.nombrePlan(),
                request.tipo(),
                request.tier(),
                request.totalCreditos(),
                request.validezDias(),
                request.precio(),
                activo
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(PlanDtoMapper.toResponse(created));
    }

    @PutMapping("/{planId}")
    @Operation(summary = "Actualiza un plan (PATCH: null no cambia el campo)")
    public PlanResponse update(@PathVariable("businessId") UUID businessId,
                               @PathVariable("planId") UUID planId,
                               @Valid @RequestBody UpdatePlanRequest request) {
        String tenantId = currentTenant.requireTenantId();
        var updated = updatePlan.execute(
                tenantId, businessId, planId,
                request.nombrePlan(),
                request.tipo(),
                request.tier(),
                request.totalCreditos(),
                request.validezDias(),
                request.precio(),
                request.activo()
        );
        return PlanDtoMapper.toResponse(updated);
    }

    @DeleteMapping("/{planId}")
    @Operation(summary = "Baja lógica del plan (activo=false)")
    public ResponseEntity<Void> delete(@PathVariable("businessId") UUID businessId,
                                       @PathVariable("planId") UUID planId) {
        String tenantId = currentTenant.requireTenantId();
        deletePlan.execute(tenantId, businessId, planId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    @Operation(summary = "Lista planes del negocio")
    public List<PlanResponse> list(@PathVariable("businessId") UUID businessId,
                                   @Parameter(description = "Si true, solo planes con activo=true")
                                   @RequestParam(name = "onlyActive", defaultValue = "false") boolean onlyActive) {
        String tenantId = currentTenant.requireTenantId();
        return listPlans.execute(tenantId, businessId, onlyActive).stream()
                .map(PlanDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/{planId}")
    @Operation(summary = "Detalle de un plan del negocio")
    public PlanResponse detail(@PathVariable("businessId") UUID businessId,
                               @PathVariable("planId") UUID planId) {
        String tenantId = currentTenant.requireTenantId();
        return PlanDtoMapper.toResponse(getPlan.execute(tenantId, businessId, planId));
    }
}

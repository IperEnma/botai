package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.BusinessHoursResponse;
import com.botai.application.agenda.dto.SaveBusinessHoursRequest;
import com.botai.application.agenda.usecase.business.SaveBusinessHoursUseCase;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;
import com.botai.application.agenda.usecase.business.ListBusinessesByTenantUseCase;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/hours")
@Tag(name = "Horarios", description = "Horarios de atención del negocio")
public class TenantBusinessHoursController {

    private final BusinessHoursRepository hoursRepository;
    private final SaveBusinessHoursUseCase saveHours;
    private final AgendaCurrentTenantService currentTenant;
    private final ListBusinessesByTenantUseCase listBusinesses;

    public TenantBusinessHoursController(BusinessHoursRepository hoursRepository,
                                         SaveBusinessHoursUseCase saveHours,
                                         AgendaCurrentTenantService currentTenant,
                                         ListBusinessesByTenantUseCase listBusinesses) {
        this.hoursRepository = hoursRepository;
        this.saveHours = saveHours;
        this.currentTenant = currentTenant;
        this.listBusinesses = listBusinesses;
    }

    @GetMapping
    @Operation(summary = "Obtiene los horarios de atención del negocio")
    public List<BusinessHoursResponse> getHours(@PathVariable UUID businessId) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);
        return hoursRepository.findByBusinessId(businessId).stream()
                .map(this::toResponse)
                .toList();
    }

    @PutMapping
    @Operation(summary = "Reemplaza los horarios de atención del negocio")
    public ResponseEntity<List<BusinessHoursResponse>> saveHours(
            @PathVariable UUID businessId,
            @Valid @RequestBody SaveBusinessHoursRequest request) {
        String tenantId = currentTenant.requireTenantId();
        listBusinesses.findOne(tenantId, businessId);

        List<BusinessHours> newHours = request.horarios().stream()
                .map(item -> new BusinessHours(
                        UUID.randomUUID(),
                        businessId,
                        item.diaSemana(),
                        item.apertura(),
                        item.cierre(),
                        item.cerrado()))
                .toList();

        List<BusinessHoursResponse> saved = saveHours.execute(tenantId, businessId, newHours)
                .stream().map(this::toResponse).toList();
        return ResponseEntity.ok(saved);
    }

    private BusinessHoursResponse toResponse(BusinessHours h) {
        return new BusinessHoursResponse(h.getId(), h.getBusinessId(),
                h.getDiaSemana(), h.getApertura(), h.getCierre(), h.isCerrado());
    }
}

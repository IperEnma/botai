package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.LoyaltySuggestionResponse;
import com.botai.application.agenda.dto.UpdateLoyaltySuggestionRequest;
import com.botai.application.agenda.usecase.loyalty.SendLoyaltySuggestionUseCase;
import com.botai.domain.agenda.model.LoyaltySuggestion;
import com.botai.domain.agenda.model.LoyaltySuggestionEstado;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.LoyaltySuggestionRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Panel de fidelización para administradores de negocio.
 * Listado y gestión de las sugerencias generadas por el motor de loyalty.
 */
@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/loyalty/suggestions")
@Tag(name = "Agenda Loyalty", description = "Panel de fidelización — sugerencias por umbral de asistencias")
@Validated
public class LoyaltySuggestionController {

    private final LoyaltySuggestionRepository suggestionRepository;
    private final SendLoyaltySuggestionUseCase sendSuggestion;
    private final AgendaCurrentTenantService currentTenant;

    public LoyaltySuggestionController(LoyaltySuggestionRepository suggestionRepository,
                                       SendLoyaltySuggestionUseCase sendSuggestion,
                                       AgendaCurrentTenantService currentTenant) {
        this.suggestionRepository = suggestionRepository;
        this.sendSuggestion = sendSuggestion;
        this.currentTenant = currentTenant;
    }

    @GetMapping
    @Operation(summary = "Listar sugerencias de fidelización (filtro opcional por estado)")
    public ResponseEntity<List<LoyaltySuggestionResponse>> list(
            @PathVariable("businessId") UUID businessId,
            @RequestParam(value = "estado", required = false) LoyaltySuggestionEstado estado) {
        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);

        List<LoyaltySuggestion> suggestions = estado != null
                ? suggestionRepository.findAllByBusinessIdAndEstado(businessId, estado)
                : suggestionRepository.findAllByBusinessId(businessId);

        return ResponseEntity.ok(suggestions.stream().map(this::toResponse).toList());
    }

    @PatchMapping("/{suggestionId}")
    @Operation(summary = "Actualizar estado de una sugerencia (SENT o DISMISSED)")
    public ResponseEntity<LoyaltySuggestionResponse> update(
            @PathVariable("businessId") UUID businessId,
            @PathVariable("suggestionId") UUID suggestionId,
            @Valid @RequestBody UpdateLoyaltySuggestionRequest request) {
        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);

        LoyaltySuggestion suggestion = suggestionRepository.findById(suggestionId)
                .filter(s -> s.getBusinessId().equals(businessId))
                .orElseThrow(() -> new IllegalArgumentException(
                        "Sugerencia no encontrada: " + suggestionId));

        LoyaltySuggestion updated = suggestionRepository.save(
                suggestion.withEstado(request.estado()));
        return ResponseEntity.ok(toResponse(updated));
    }

    @PostMapping("/{suggestionId}/send")
    @Operation(summary = "Enviar notificación in-app a partir de una sugerencia de fidelización")
    public ResponseEntity<LoyaltySuggestionResponse> send(
            @PathVariable("businessId") UUID businessId,
            @PathVariable("suggestionId") UUID suggestionId) {
        String tenantId = currentTenant.requireBusinessOwnedByCurrentTenant(businessId).getTenantId();
        LoyaltySuggestion updated = sendSuggestion.execute(tenantId, businessId, suggestionId);
        return ResponseEntity.ok(toResponse(updated));
    }

    private LoyaltySuggestionResponse toResponse(LoyaltySuggestion s) {
        return new LoyaltySuggestionResponse(
                s.getId(), s.getBusinessId(), s.getUserId(),
                s.getTriggerRule(), s.getEstado(),
                s.getCreatedAt(), s.getUpdatedAt());
    }
}

package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.ClientResponse;
import com.botai.application.agenda.dto.CreateClientRequest;
import com.botai.application.agenda.support.AgendaClientResolver;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.UserRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/me/businesses/{businessId}/clients")
@Tag(name = "Agenda Me · Clients", description = "Clientes del negocio (panel tenant autenticado)")
@Validated
public class TenantClientsController {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;
    private final AgendaCurrentTenantService currentTenant;

    public TenantClientsController(BusinessRepository businessRepository,
                                   UserRepository userRepository,
                                   AgendaCurrentTenantService currentTenant) {
        this.businessRepository = businessRepository;
        this.userRepository = userRepository;
        this.currentTenant = currentTenant;
    }

    @GetMapping
    @Operation(summary = "Busca clientes del tenant por nombre o teléfono")
    public List<ClientResponse> search(
            @PathVariable("businessId") UUID businessId,
            @RequestParam(value = "q", defaultValue = "") String q) {
        String tenantId = resolveTenant(businessId);
        return userRepository.searchClients(tenantId, q.trim()).stream()
                .map(u -> new ClientResponse(u.getId(), u.getNombre(), u.getEmail(), u.getTelefono()))
                .toList();
    }

    @PostMapping
    @Operation(summary = "Crea o reutiliza un cliente del tenant (teléfono obligatorio)")
    public ResponseEntity<ClientResponse> create(
            @PathVariable("businessId") UUID businessId,
            @Valid @RequestBody CreateClientRequest request) {
        String tenantId = resolveTenant(businessId);
        User saved = AgendaClientResolver.resolveOrCreate(
                userRepository,
                tenantId,
                request.nombre(),
                request.email(),
                request.telefono());
        return ResponseEntity.ok(new ClientResponse(
                saved.getId(), saved.getNombre(), saved.getEmail(), saved.getTelefono()));
    }

    private String resolveTenant(UUID businessId) {
        currentTenant.requireBusinessOwnedByCurrentTenant(businessId);
        return businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }
}

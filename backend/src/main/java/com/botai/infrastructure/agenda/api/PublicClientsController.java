package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.ClientResponse;
import com.botai.application.agenda.dto.CreateClientRequest;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
@RequestMapping("/api/agenda/public/businesses/{businessId}/clients")
@Tag(name = "Agenda Public · Clients", description = "Gestión de clientes desde la vista pública")
public class PublicClientsController {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;

    public PublicClientsController(BusinessRepository businessRepository,
                                   UserRepository userRepository) {
        this.businessRepository = businessRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    @Operation(summary = "Busca clientes por nombre o teléfono")
    public List<ClientResponse> search(
            @PathVariable("businessId") UUID businessId,
            @RequestParam(value = "q", defaultValue = "") String q) {

        final String tenantId = resolveTenant(businessId);
        return userRepository.searchClients(tenantId, q.trim()).stream()
                .map(u -> new ClientResponse(u.getId(), u.getNombre(), u.getEmail(), u.getTelefono()))
                .toList();
    }

    @PostMapping
    @Operation(summary = "Crea un nuevo cliente (teléfono obligatorio)")
    public ResponseEntity<ClientResponse> create(
            @PathVariable("businessId") UUID businessId,
            @Valid @RequestBody CreateClientRequest request) {

        final String tenantId = resolveTenant(businessId);
        final String phoneNorm = AgendaPhoneNormalizer.normalize(request.telefono());
        if (!AgendaPhoneNormalizer.isValid(phoneNorm)) {
            throw new IllegalArgumentException("Teléfono obligatorio (mínimo 7 dígitos)");
        }

        if (request.email() != null && !request.email().isBlank()) {
            String email = request.email().trim().toLowerCase();
            var existing = userRepository.findByTenantIdAndEmail(tenantId, email);
            if (existing.isPresent()) {
                User u = existing.get();
                User saved = ensurePhone(u, request.nombre().trim(), email, phoneNorm);
                return ResponseEntity.ok(toResponse(saved));
            }
        }

        User saved = userRepository.save(new User(
                null,
                tenantId,
                request.nombre().trim(),
                request.email() != null && !request.email().isBlank()
                        ? request.email().trim().toLowerCase() : null,
                phoneNorm,
                UserType.CLIENT,
                true,
                null,
                null
        ));

        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    /**
     * Si el cliente ya existía sin teléfono, lo actualiza; si tenía otro teléfono, se mantiene.
     */
    private User ensurePhone(User existing, String nombre, String email, String phoneNorm) {
        if (existing.getTelefono() != null && !existing.getTelefono().isBlank()) {
            return existing;
        }
        return userRepository.save(new User(
                existing.getId(),
                existing.getTenantId(),
                nombre.isBlank() ? existing.getNombre() : nombre,
                email,
                phoneNorm,
                existing.getTipoUsuario(),
                existing.isActivo(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        ));
    }

    private static ClientResponse toResponse(User u) {
        return new ClientResponse(u.getId(), u.getNombre(), u.getEmail(), u.getTelefono());
    }

    private String resolveTenant(UUID businessId) {
        return businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }
}

package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.LinkTenantGoogleEmailRequest;
import com.botai.agenda.application.dto.LinkTenantIdentifierRequest;
import com.botai.agenda.application.dto.TenantAdminContextResponse;
import com.botai.agenda.application.usecase.tenant.LinkTenantIdentifierUseCase;
import com.botai.agenda.application.usecase.tenant.LinkTenantGoogleEmailUseCase;
import com.botai.agenda.domain.repository.TenantAccountRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Locale;

/**
 * Resuelve el {@code tenantId} del admin AGENDA a partir del correo de la cuenta.
 *
 * <p>Misma confianza que el resto del panel (Bearer opcional); el email lo envía el cliente
 * tras login con Google. Cuando exista verificación de token en servidor, este header puede obviarse.</p>
 *
 * <p>Registro por WhatsApp usa la columna {@code numero} (solo dígitos). El Gmail de la sesión se
 * resuelve con {@code google_linked_email} tras {@code POST /tenant-admin/link}.</p>
 */
@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Tenant admin", description = "Contexto del administrador de tenant")
public class MeTenantAdminController {

    private final TenantAccountRepository tenantAccountRepository;
    private final LinkTenantGoogleEmailUseCase linkTenantGoogleEmailUseCase;
    private final LinkTenantIdentifierUseCase linkTenantIdentifierUseCase;

    public MeTenantAdminController(TenantAccountRepository tenantAccountRepository,
                                   LinkTenantGoogleEmailUseCase linkTenantGoogleEmailUseCase,
                                   LinkTenantIdentifierUseCase linkTenantIdentifierUseCase) {
        this.tenantAccountRepository = tenantAccountRepository;
        this.linkTenantGoogleEmailUseCase = linkTenantGoogleEmailUseCase;
        this.linkTenantIdentifierUseCase = linkTenantIdentifierUseCase;
    }

    @GetMapping("/tenant-admin")
    @Operation(summary = "Obtener tenantId del administrador por email de cuenta (principal o Google vinculado)")
    public ResponseEntity<TenantAdminContextResponse> resolveTenantAdmin(
            @AuthenticationPrincipal Jwt jwt) {
        String email = jwt == null ? null : jwt.getClaimAsString("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        String normalized = email.strip().toLowerCase(Locale.ROOT);
        return tenantAccountRepository.findByEmail(normalized)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(normalized))
                .map(account -> ResponseEntity.ok(new TenantAdminContextResponse(account.getTenantId())))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/tenant-admin/link")
    @Operation(summary = "Vincular correo de Google a cuenta registrada por WhatsApp (código de acceso)")
    public ResponseEntity<TenantAdminContextResponse> linkGoogleEmail(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody LinkTenantGoogleEmailRequest body) {
        String email = jwt == null ? null : jwt.getClaimAsString("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        TenantAdminContextResponse response =
                linkTenantGoogleEmailUseCase.execute(email, body.accessCode());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/tenant-admin/identifiers")
    @Operation(summary = "Agregar email o número a la cuenta Agenda actual (exactamente uno)")
    public ResponseEntity<TenantAdminContextResponse> linkIdentifier(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody LinkTenantIdentifierRequest body) {
        String adminEmail = jwt == null ? null : jwt.getClaimAsString("email");
        if (adminEmail == null || adminEmail.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        TenantAdminContextResponse response = linkTenantIdentifierUseCase.execute(
                adminEmail, body.email(), body.numero());
        return ResponseEntity.ok(response);
    }
}

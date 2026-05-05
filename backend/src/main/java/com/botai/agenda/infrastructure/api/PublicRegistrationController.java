package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.RegisterTenantRequest;
import com.botai.agenda.application.dto.RegisterTenantResponse;
import com.botai.agenda.application.dto.TenantAccessResponse;
import com.botai.agenda.application.usecase.tenant.RegisterTenantUseCase;
import com.botai.agenda.domain.repository.TenantAccountRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoints públicos para registro y acceso de tenants en el módulo AGENDA.
 * No requieren autenticación ni AgendaFeatureGuard.
 */
@RestController
@RequestMapping("/api/agenda/public")
@Tag(name = "Registro público", description = "Registro y acceso a negocios en AGENDA")
public class PublicRegistrationController {

    private final RegisterTenantUseCase registerTenantUseCase;
    private final TenantAccountRepository tenantAccountRepository;

    public PublicRegistrationController(RegisterTenantUseCase registerTenantUseCase,
                                        TenantAccountRepository tenantAccountRepository) {
        this.registerTenantUseCase = registerTenantUseCase;
        this.tenantAccountRepository = tenantAccountRepository;
    }

    @PostMapping("/register")
    @Operation(
            summary = "Registra un nuevo tenant con su negocio",
            description = "Crea la cuenta de tenant, el usuario admin, la configuración y el negocio principal en una sola operación."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Tenant registrado exitosamente"),
            @ApiResponse(responseCode = "400", description = "Request inválido (campos requeridos faltantes o mal formateados)"),
            @ApiResponse(responseCode = "409", description = "El email ya está registrado")
    })
    public ResponseEntity<RegisterTenantResponse> register(
            @Valid @RequestBody RegisterTenantRequest request) {
        RegisterTenantResponse response = registerTenantUseCase.execute(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/tenants/by-code/{accessCode}")
    @Operation(
            summary = "Obtiene el tenantId a partir del código de acceso",
            description = "Permite a un dueño de negocio recuperar su tenantId usando el código de 8 caracteres recibido al registrarse."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Tenant encontrado"),
            @ApiResponse(responseCode = "404", description = "Código de acceso inválido o no encontrado")
    })
    public ResponseEntity<TenantAccessResponse> getByCode(@PathVariable String accessCode) {
        return tenantAccountRepository.findByAccessCode(accessCode.toUpperCase())
                .map(account -> ResponseEntity.ok(new TenantAccessResponse(account.getTenantId())))
                .orElse(ResponseEntity.notFound().build());
    }
}

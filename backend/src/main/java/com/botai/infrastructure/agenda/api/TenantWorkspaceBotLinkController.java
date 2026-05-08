package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.LinkBotToAgendaBusinessesRequest;
import com.botai.application.agenda.usecase.bot.LinkBotToAgendaBusinessesUseCase;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashSet;

/**
 * Asignación explícita bot ↔ negocios Agenda (mismo {@code tenant_id} que {@code bot.tenant_id}).
 */
@RestController
@RequestMapping("/api/agenda/me/bots")
@Tag(name = "Bot ↔ Agenda", description = "Vincular el bot del workspace con uno o varios negocios")
public class TenantWorkspaceBotLinkController {

    private final AgendaCurrentTenantService currentTenant;
    private final LinkBotToAgendaBusinessesUseCase linkBotToAgendaBusinessesUseCase;

    public TenantWorkspaceBotLinkController(AgendaCurrentTenantService currentTenant,
                                            LinkBotToAgendaBusinessesUseCase linkBotToAgendaBusinessesUseCase) {
        this.currentTenant = currentTenant;
        this.linkBotToAgendaBusinessesUseCase = linkBotToAgendaBusinessesUseCase;
    }

    @PutMapping("/{botId}/linked-businesses")
    @Operation(summary = "Define qué negocios de Agenda atiende este bot (reemplazo completo)",
            description = "Lista vacía desvincula todos los negocios de ese bot. Un negocio no puede quedar ligado a dos bots.")
    public ResponseEntity<Void> replaceLinkedBusinesses(
            @PathVariable long botId,
            @Valid @RequestBody LinkBotToAgendaBusinessesRequest request) {
        String tenantId = currentTenant.requireTenantId();
        linkBotToAgendaBusinessesUseCase.execute(tenantId, botId, new LinkedHashSet<>(request.businessIds()));
        return ResponseEntity.noContent().build();
    }
}

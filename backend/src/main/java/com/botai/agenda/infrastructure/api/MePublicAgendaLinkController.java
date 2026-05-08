package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.PublicAgendaLinkResponse;
import com.botai.agenda.application.usecase.business.GetOrCreatePublicAgendaLinkUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Public link", description = "Link público persistente por negocio/tenant")
public class MePublicAgendaLinkController {

    private final GetOrCreatePublicAgendaLinkUseCase useCase;
    private final String frontendBaseUrl;

    public MePublicAgendaLinkController(
            GetOrCreatePublicAgendaLinkUseCase useCase,
            @Value("${agenda.public.base-url:}") String frontendBaseUrl
    ) {
        this.useCase = useCase;
        this.frontendBaseUrl = frontendBaseUrl;
    }

    @GetMapping("/public-link")
    @Operation(summary = "Obtener (y si falta, crear) el link público amigable de la Agenda para este tenant")
    public ResponseEntity<PublicAgendaLinkResponse> getPublicLink(HttpServletRequest request) {
        String origin = request.getScheme() + "://" + request.getServerName()
                + ((request.getServerPort() == 80 || request.getServerPort() == 443) ? "" : ":" + request.getServerPort());
        final String base = (frontendBaseUrl == null || frontendBaseUrl.isBlank())
                ? origin
                : frontendBaseUrl.trim();
        return ResponseEntity.ok(useCase.execute(base));
    }
}


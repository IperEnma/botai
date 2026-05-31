package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.PublicAgendaLinkResponse;
import com.botai.application.agenda.usecase.business.GetOrCreatePublicAgendaLinkUseCase;
import com.botai.infrastructure.config.AppUrlProperties;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Public link", description = "Link público persistente por negocio/tenant")
public class MePublicAgendaLinkController {

    private final GetOrCreatePublicAgendaLinkUseCase useCase;
    private final AppUrlProperties appUrls;

    public MePublicAgendaLinkController(
            GetOrCreatePublicAgendaLinkUseCase useCase,
            AppUrlProperties appUrls
    ) {
        this.useCase = useCase;
        this.appUrls = appUrls;
    }

    @GetMapping("/public-link")
    @Operation(summary = "Obtener (y si falta, crear) el link público amigable de la Agenda para este tenant")
    public ResponseEntity<PublicAgendaLinkResponse> getPublicLink(HttpServletRequest request) {
        String configured = appUrls.normalizedFrontend();
        final String base;
        if (configured.isBlank()) {
            base = request.getScheme() + "://" + request.getServerName()
                    + ((request.getServerPort() == 80 || request.getServerPort() == 443)
                    ? "" : ":" + request.getServerPort());
        } else {
            base = configured;
        }
        return ResponseEntity.ok(useCase.execute(base));
    }
}

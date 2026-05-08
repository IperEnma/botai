package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.ResolveBusinessBySlugResponse;
import com.botai.agenda.domain.repository.BusinessRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agenda/public")
@Tag(name = "Agenda Public · Links", description = "Resolución de links públicos amigables")
public class PublicLinkController {

    private final BusinessRepository businessRepository;

    public PublicLinkController(BusinessRepository businessRepository) {
        this.businessRepository = businessRepository;
    }

    @GetMapping("/links/{slug}")
    @Operation(summary = "Resolver slug público → businessId")
    public ResponseEntity<ResolveBusinessBySlugResponse> resolve(@PathVariable("slug") String slug) {
        return businessRepository.findByPublicSlug(slug)
                .map(b -> ResponseEntity.ok(new ResolveBusinessBySlugResponse(b.getId().toString())))
                .orElse(ResponseEntity.notFound().build());
    }
}


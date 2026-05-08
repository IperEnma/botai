package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.dto.PublicAgendaLinkResponse;
import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GetOrCreatePublicAgendaLinkUseCase {

    private final AgendaCurrentTenantService currentTenant;
    private final BusinessRepository businessRepository;

    public GetOrCreatePublicAgendaLinkUseCase(
            AgendaCurrentTenantService currentTenant,
            BusinessRepository businessRepository
    ) {
        this.currentTenant = currentTenant;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public PublicAgendaLinkResponse execute(String origin) {
        String tenantId = currentTenant.requireTenantId();
        Business business = businessRepository.findAllByTenantId(tenantId).stream()
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("No hay negocio para este tenant."));

        String slug = ensureSlug(business);
        // Flutter web usa hash routing: /#/agenda/<slug>
        String url = origin + "/#/agenda/" + slug;
        return new PublicAgendaLinkResponse(slug, url, business.getId().toString());
    }

    private String ensureSlug(Business b) {
        String existing = b.getPublicSlug();
        if (existing != null && !existing.isBlank()) {
            return existing.trim();
        }
        String slug = AgendaPublicSlug.forNewBusiness(b.getId(), b.getNombre());

        Business updated = new Business(
                b.getId(),
                b.getTenantId(),
                b.getNombre(),
                b.getDescripcion(),
                b.getOwnerUserId(),
                b.getSearchTags(),
                b.isActivo(),
                b.getLogoUrl(),
                b.getColorPrimario(),
                b.getInstagramUrl(),
                b.getTiktokUrl(),
                b.getFacebookUrl(),
                b.getColorFondo(),
                b.getFontFamily(),
                slug,
                b.getBotId(),
                b.getDeletedAt(),
                b.getCreatedAt(),
                b.getUpdatedAt()
        );
        businessRepository.save(updated);
        return slug;
    }
}


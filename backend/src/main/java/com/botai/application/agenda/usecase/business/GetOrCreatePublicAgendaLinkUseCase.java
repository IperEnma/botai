package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.dto.PublicAgendaLinkResponse;
import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.application.agenda.support.CompanySlugSupport;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.security.AgendaCurrentTenantService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
        List<Business> active = businessRepository.findAllByTenantId(tenantId).stream()
                .filter(Business::isActivo)
                .toList();
        if (active.isEmpty()) {
            throw new IllegalStateException("No hay negocio para este tenant.");
        }

        Business primary = active.get(0);
        String slug = ensureSlug(primary);
        String companySlug = ensureCompanySlug(primary, tenantId);
        String url = buildPublicUrl(origin, active.size(), companySlug, slug);

        return new PublicAgendaLinkResponse(slug, url, primary.getId().toString(), companySlug);
    }

    static String buildPublicUrl(String origin, int branchCount, String companySlug, String branchSlug) {
        String base = origin.endsWith("/") ? origin.substring(0, origin.length() - 1) : origin;
        if (branchCount > 1) {
            return base + "/#/reservar?company=" + companySlug;
        }
        return base + "/#/reservar/" + branchSlug;
    }

    private String ensureSlug(Business b) {
        String existing = b.getPublicSlug();
        if (existing != null && !existing.isBlank()) {
            return existing.trim();
        }
        String slug = AgendaPublicSlug.forNewBusiness(b.getId(), b.getNombre());
        businessRepository.save(copyWithSlugs(b, slug, b.getCompanySlug()));
        return slug;
    }

    private String ensureCompanySlug(Business b, String tenantId) {
        String existing = b.getCompanySlug();
        if (existing != null && !existing.isBlank()) {
            return existing.trim();
        }
        String companySlug = CompanySlugSupport.resolveForNewBusiness(businessRepository, tenantId, b.getNombre());
        businessRepository.save(copyWithSlugs(b, b.getPublicSlug(), companySlug));
        return companySlug;
    }

    private static Business copyWithSlugs(Business b, String publicSlug, String companySlug) {
        return new Business(
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
                publicSlug,
                companySlug,
                b.getBotId(),
                b.getDeletedAt(),
                b.getCreatedAt(),
                b.getUpdatedAt()
        );
    }
}

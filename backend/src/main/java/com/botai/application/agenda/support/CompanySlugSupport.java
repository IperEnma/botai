package com.botai.application.agenda.support;

import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;

import java.util.List;

public final class CompanySlugSupport {

    private CompanySlugSupport() {
    }

    public static String resolveForNewBusiness(BusinessRepository repository, String tenantId, String nombre) {
        List<Business> siblings = repository.findAllByTenantId(tenantId);
        for (Business sibling : siblings) {
            if (sibling.getCompanySlug() != null && !sibling.getCompanySlug().isBlank()) {
                return sibling.getCompanySlug().strip();
            }
        }
        return AgendaPublicSlug.compactSlug(nombre);
    }
}

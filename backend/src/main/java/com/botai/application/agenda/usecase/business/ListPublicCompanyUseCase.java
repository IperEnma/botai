package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.dto.PublicCompanyBranchResponse;
import com.botai.application.agenda.dto.PublicCompanyResponse;
import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ListPublicCompanyUseCase {

    private final BusinessRepository businessRepository;

    public ListPublicCompanyUseCase(BusinessRepository businessRepository) {
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public PublicCompanyResponse execute(String companySlugRaw) {
        String companySlug = AgendaPublicSlug.normalizeCompanySlug(companySlugRaw);
        if (companySlug.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "company inválido");
        }

        List<Business> branches = businessRepository.findAllActiveByCompanySlug(companySlug);
        if (branches.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Marca no encontrada");
        }

        Business brand = branches.get(0);
        String brandName = deriveBrandName(branches);
        String tagline = brand.getDescripcion();

        List<PublicCompanyBranchResponse> branchResponses = branches.stream()
                .map(b -> new PublicCompanyBranchResponse(
                        b.getId(),
                        b.getNombre(),
                        b.getDescripcion(),
                        b.getPublicSlug(),
                        b.getLogoUrl(),
                        b.getColorPrimario()))
                .toList();

        return new PublicCompanyResponse(
                companySlug,
                brandName,
                tagline,
                brand.getLogoUrl(),
                brand.getColorPrimario(),
                brand.getColorFondo(),
                brand.getFontFamily(),
                branchResponses
        );
    }

    private static String deriveBrandName(List<Business> branches) {
        if (branches.size() == 1) {
            return branches.get(0).getNombre();
        }
        String first = branches.get(0).getNombre();
        int paren = first.indexOf('(');
        if (paren > 0) {
            return first.substring(0, paren).strip();
        }
        return first;
    }
}

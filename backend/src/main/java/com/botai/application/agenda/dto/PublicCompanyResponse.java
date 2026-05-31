package com.botai.application.agenda.dto;

import java.util.List;

public record PublicCompanyResponse(
        String companySlug,
        String brandName,
        String tagline,
        String logoUrl,
        String colorPrimario,
        String colorFondo,
        String fontFamily,
        List<PublicCompanyBranchResponse> branches
) {
}

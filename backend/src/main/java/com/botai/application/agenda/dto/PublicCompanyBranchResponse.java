package com.botai.application.agenda.dto;

import java.util.List;
import java.util.UUID;

public record PublicCompanyBranchResponse(
        UUID id,
        String nombre,
        String descripcion,
        String publicSlug,
        String logoUrl,
        String colorPrimario
) {
}

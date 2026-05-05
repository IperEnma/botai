package com.botai.agenda.application.dto;

import java.util.List;
import java.util.UUID;

public record BusinessSummaryResponse(
        UUID id,
        String tenantId,
        String nombre,
        String descripcion,
        List<String> categorySlugs,
        String logoUrl
) {
}

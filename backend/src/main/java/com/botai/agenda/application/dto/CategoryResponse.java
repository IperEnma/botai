package com.botai.agenda.application.dto;

import java.util.List;
import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String nombre,
        String slug,
        String icono,
        List<String> synonyms,
        boolean activo
) {
}

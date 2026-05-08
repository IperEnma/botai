package com.botai.application.agenda.dto;

import java.util.List;

public record UpdateCategoryRequest(
        String nombre,
        String icono,
        List<String> synonyms,
        Boolean activo
) {
}

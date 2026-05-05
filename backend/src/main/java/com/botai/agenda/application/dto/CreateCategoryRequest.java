package com.botai.agenda.application.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.List;

public record CreateCategoryRequest(
        @NotBlank String nombre,
        @NotBlank String slug,
        String icono,
        List<String> synonyms
) {
}

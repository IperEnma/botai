package com.botai.agenda.application.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.List;
import java.util.UUID;

public record CreateBusinessRequest(
        @NotBlank String nombre,
        String descripcion,
        UUID ownerUserId,
        List<String> searchTags
) {
}

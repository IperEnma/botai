package com.botai.application.agenda.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.NotBlank;

import java.util.List;
import java.util.UUID;

public record CreateBusinessRequest(
        @NotBlank String nombre,
        String descripcion,
        UUID ownerUserId,
        @JsonDeserialize(contentUsing = SearchTagDtoDeserializer.class)
        List<SearchTagDto> searchTags
) {
}

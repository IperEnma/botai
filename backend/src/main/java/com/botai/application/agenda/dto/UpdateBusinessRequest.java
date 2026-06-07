package com.botai.application.agenda.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.Size;

import java.util.List;

public record UpdateBusinessRequest(
        @Size(min = 1, max = 255) String nombre,
        @Size(max = 2000) String descripcion,
        @Size(max = 50)
        @JsonDeserialize(contentUsing = SearchTagDtoDeserializer.class)
        List<SearchTagDto> searchTags,
        Boolean activo,
        @Size(max = 500) String logoUrl,
        @Size(max = 9) String colorPrimario,
        @Size(max = 500) String instagramUrl,
        @Size(max = 500) String tiktokUrl,
        @Size(max = 500) String facebookUrl,
        @Size(max = 20) String colorFondo,
        @Size(max = 100) String fontFamily,
        @Size(max = 500) String bannerUrl,
        @Size(max = 500) String direccion
) {
}

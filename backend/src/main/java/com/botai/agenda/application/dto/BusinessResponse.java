package com.botai.agenda.application.dto;

import java.util.List;
import java.util.UUID;

public record BusinessResponse(
        UUID id,
        String tenantId,
        String nombre,
        String descripcion,
        UUID ownerUserId,
        List<String> searchTags,
        boolean activo,
        String logoUrl,
        String colorPrimario,
        String instagramUrl,
        String tiktokUrl,
        String facebookUrl,
        String colorFondo,
        String fontFamily,
        List<String> categorias
) {
}

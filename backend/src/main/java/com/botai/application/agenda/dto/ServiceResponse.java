package com.botai.application.agenda.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record ServiceResponse(
        UUID id,
        UUID businessId,
        String nombre,
        String descripcion,
        int duracionMin,
        BigDecimal precio,
        boolean activo
) {
}

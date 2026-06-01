package com.botai.application.agenda.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record UpdateServiceRequest(
        @NotBlank @Size(max = 255) String nombre,
        @Size(max = 2000) String descripcion,
        @Positive int duracionMin,
        @DecimalMin("0.00") BigDecimal precio,
        @NotNull Boolean activo,
        @Pattern(regexp = "GENERAL|BY_STAFF", message = "schedulingMode debe ser GENERAL o BY_STAFF")
        String schedulingMode,
        List<UUID> staffMemberIds
) {
    public String schedulingModeOrDefault() {
        return schedulingMode != null && !schedulingMode.isBlank()
                ? schedulingMode.trim().toUpperCase()
                : "GENERAL";
    }
}

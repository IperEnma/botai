package com.botai.application.agenda.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record UpdateServiceRequest(
        @NotBlank @Size(max = 255) String nombre,
        @Size(max = 2000) String descripcion,
        @Positive int duracionMin,
        @DecimalMin("0.00") BigDecimal precio,
        @NotNull Boolean activo
) {}

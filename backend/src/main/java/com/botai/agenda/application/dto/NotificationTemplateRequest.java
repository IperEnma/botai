package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.NotificationCanal;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record NotificationTemplateRequest(
        @NotBlank @Size(max = 60) String codigo,
        @NotNull NotificationCanal canal,
        @NotBlank @Size(max = 255) String titulo,
        @NotBlank String cuerpo
) {}

package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.NotificationCanal;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationTemplateResponse(
        UUID id,
        UUID businessId,
        String codigo,
        NotificationCanal canal,
        String titulo,
        String cuerpo,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}

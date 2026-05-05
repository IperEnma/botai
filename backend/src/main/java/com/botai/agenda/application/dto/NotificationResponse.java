package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.NotificationCanal;
import com.botai.agenda.domain.model.NotificationEstado;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        UUID businessId,
        NotificationCanal canal,
        String titulo,
        String cuerpo,
        NotificationEstado estado,
        LocalDateTime createdAt
) {}

package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationEstado;

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

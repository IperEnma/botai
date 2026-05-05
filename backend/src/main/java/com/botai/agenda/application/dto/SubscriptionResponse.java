package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.SubscriptionEstado;

import java.time.LocalDateTime;
import java.util.UUID;

public record SubscriptionResponse(
        UUID id,
        UUID userId,
        UUID planId,
        UUID businessId,
        int saldoActual,
        LocalDateTime fechaInicio,
        LocalDateTime fechaExpiracion,
        SubscriptionEstado estado,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}

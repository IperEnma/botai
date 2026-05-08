package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.SubscriptionEstado;

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

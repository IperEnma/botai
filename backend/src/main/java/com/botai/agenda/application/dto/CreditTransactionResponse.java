package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.CreditMotivo;

import java.time.LocalDateTime;
import java.util.UUID;

public record CreditTransactionResponse(
        UUID id,
        UUID subscriptionId,
        int monto,
        CreditMotivo motivo,
        UUID bookingId,
        LocalDateTime createdAt
) {
}

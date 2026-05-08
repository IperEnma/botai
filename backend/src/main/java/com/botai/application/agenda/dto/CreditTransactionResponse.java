package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.CreditMotivo;

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

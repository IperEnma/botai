package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.LoyaltySuggestionEstado;

import java.time.LocalDateTime;
import java.util.UUID;

public record LoyaltySuggestionResponse(
        UUID id,
        UUID businessId,
        UUID userId,
        String triggerRule,
        LoyaltySuggestionEstado estado,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}

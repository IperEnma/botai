package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.LoyaltySuggestionEstado;

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

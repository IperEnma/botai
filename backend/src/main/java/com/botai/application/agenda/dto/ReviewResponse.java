package com.botai.application.agenda.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record ReviewResponse(
        UUID id,
        UUID businessId,
        UUID bookingId,
        UUID staffMemberId,
        int rating,
        String comentario,
        LocalDateTime createdAt
) {}

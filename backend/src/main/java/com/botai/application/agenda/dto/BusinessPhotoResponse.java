package com.botai.application.agenda.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record BusinessPhotoResponse(
        UUID id,
        UUID businessId,
        String url,
        int orden,
        LocalDateTime createdAt
) {}

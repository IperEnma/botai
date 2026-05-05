package com.botai.agenda.application.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record StaffMemberResponse(
        UUID id,
        UUID businessId,
        String nombre,
        String rol,
        String avatarUrl,
        boolean activo,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}

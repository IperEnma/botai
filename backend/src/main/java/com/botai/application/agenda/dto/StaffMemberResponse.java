package com.botai.application.agenda.dto;

import com.fasterxml.jackson.annotation.JsonRawValue;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record StaffMemberResponse(
        UUID id,
        UUID businessId,
        String nombre,
        String rol,
        String avatarUrl,
        String telefono,
        String email,
        String bio,
        String color,
        boolean activo,
        String status,
        @JsonRawValue String customSchedule,
        List<UUID> serviceIds,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        Double rating,
        int reviewCount
) {
}

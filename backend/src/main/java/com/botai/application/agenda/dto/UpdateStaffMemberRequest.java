package com.botai.application.agenda.dto;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateStaffMemberRequest(
        @NotBlank @Size(max = 100) String nombre,
        @Size(max = 100) String rol,
        @Size(max = 500) String avatarUrl,
        @Size(max = 50) String telefono,
        @Size(max = 200) String email,
        String bio,
        @Size(max = 7) String color,
        @NotBlank @Pattern(regexp = "ACTIVO|PAUSADO",
                message = "status debe ser ACTIVO o PAUSADO") String status,
        JsonNode customSchedule
) {
}

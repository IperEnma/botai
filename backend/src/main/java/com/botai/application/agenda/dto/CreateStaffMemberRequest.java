package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateStaffMemberRequest(
        @NotBlank @Size(max = 100) String nombre,
        @Size(max = 100) String rol,
        @Size(max = 500) String avatarUrl,
        @Size(max = 50) String telefono,
        @Size(max = 7) String color
) {
}

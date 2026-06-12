package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateStaffMemberRequest(
        @NotBlank
        @Size(max = 100)
        @Pattern(
                regexp = "^[a-zA-ZáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙüÜñÑ\\s']+$",
                message = "nombre solo puede contener letras y espacios")
        String nombre,
        @Size(max = 100) String rol,
        @Size(max = 500) String avatarUrl,
        @NotBlank
        @Size(max = 50)
        @Pattern(
                regexp = "^\\+?[0-9]{6,}$",
                message = "telefono solo puede contener números (mínimo 6 dígitos)")
        String telefono,
        @Size(max = 7) String color
) {
}

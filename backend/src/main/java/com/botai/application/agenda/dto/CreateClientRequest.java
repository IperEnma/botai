package com.botai.application.agenda.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateClientRequest(
        @NotBlank @Size(max = 120) String nombre,
        @Email @Size(max = 200) String email,
        @NotBlank @Size(min = 7, max = 32) String telefono
) {}

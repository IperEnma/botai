package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdatePublicClientProfileRequest(
        @NotBlank @Size(max = 120) String nombre
) {}

package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendPhoneVerificationRequest(
        @NotBlank @Size(max = 32) String telefono
) {}

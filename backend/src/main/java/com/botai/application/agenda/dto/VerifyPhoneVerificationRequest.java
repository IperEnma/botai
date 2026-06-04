package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record VerifyPhoneVerificationRequest(
        @NotBlank @Size(max = 32) String telefono,
        @NotBlank @Size(max = 8) String code
) {}

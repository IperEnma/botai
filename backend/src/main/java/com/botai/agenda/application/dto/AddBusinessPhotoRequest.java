package com.botai.agenda.application.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AddBusinessPhotoRequest(
        @NotBlank @Size(max = 500) String url
) {}

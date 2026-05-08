package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;
import java.util.UUID;

public record AssociateCategoriesRequest(
        @NotEmpty List<UUID> categoryIds
) {
}

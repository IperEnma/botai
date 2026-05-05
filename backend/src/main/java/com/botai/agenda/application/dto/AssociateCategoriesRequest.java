package com.botai.agenda.application.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;
import java.util.UUID;

public record AssociateCategoriesRequest(
        @NotEmpty List<UUID> categoryIds
) {
}

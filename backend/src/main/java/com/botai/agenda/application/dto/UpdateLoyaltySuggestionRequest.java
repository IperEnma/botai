package com.botai.agenda.application.dto;

import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import jakarta.validation.constraints.NotNull;

public record UpdateLoyaltySuggestionRequest(
        @NotNull LoyaltySuggestionEstado estado
) {}

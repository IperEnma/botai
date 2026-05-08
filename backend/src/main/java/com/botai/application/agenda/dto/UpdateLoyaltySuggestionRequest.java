package com.botai.application.agenda.dto;

import com.botai.domain.agenda.model.LoyaltySuggestionEstado;
import jakarta.validation.constraints.NotNull;

public record UpdateLoyaltySuggestionRequest(
        @NotNull LoyaltySuggestionEstado estado
) {}

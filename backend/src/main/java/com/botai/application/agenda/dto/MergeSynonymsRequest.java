package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record MergeSynonymsRequest(
        @NotEmpty List<String> synonyms
) {
}

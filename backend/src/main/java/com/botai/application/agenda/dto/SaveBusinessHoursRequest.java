package com.botai.application.agenda.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.LocalTime;
import java.util.List;

public record SaveBusinessHoursRequest(@NotNull @Valid List<HoraItem> horarios) {

    public record HoraItem(
            @NotNull @Min(0) @Max(6) Integer diaSemana,
            LocalTime apertura,
            LocalTime cierre,
            boolean cerrado
    ) {}
}

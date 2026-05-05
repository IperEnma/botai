package com.botai.agenda.application.dto;

import java.time.LocalTime;
import java.util.UUID;

public record BusinessHoursResponse(
        UUID id,
        UUID businessId,
        int diaSemana,
        LocalTime apertura,
        LocalTime cierre,
        boolean cerrado
) {}

package com.botai.application.agenda.dto;

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

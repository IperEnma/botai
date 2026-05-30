package com.botai.application.agenda.dto;

import java.util.UUID;

public record ClientResponse(
        UUID id,
        String nombre,
        String email,
        String telefono
) {}

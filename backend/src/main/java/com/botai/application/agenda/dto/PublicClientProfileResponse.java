package com.botai.application.agenda.dto;

import java.util.UUID;

public record PublicClientProfileResponse(
        UUID id,
        String nombre,
        String telefono,
        String email,
        /** true si aún no tenemos nombre real (solo teléfono verificado). */
        boolean needsName
) {}

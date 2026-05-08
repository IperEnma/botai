package com.botai.infrastructure.agenda.security;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * Helpers para extraer datos del JWT (Google ID token).
 */
public final class AgendaAuthContext {

    private AgendaAuthContext() {}

    public static String requireEmail() {
        Jwt jwt = currentJwt();
        String email = jwt == null ? null : jwt.getClaimAsString("email");
        if (email == null || email.isBlank()) {
            throw new IllegalStateException("No hay email en el token.");
        }
        return email;
    }

    public static Jwt currentJwt() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return null;
        Object principal = auth.getPrincipal();
        if (principal instanceof Jwt jwt) return jwt;
        Object credentials = auth.getCredentials();
        if (credentials instanceof Jwt jwt) return jwt;
        return null;
    }
}


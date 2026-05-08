package com.botai.agenda.infrastructure.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.web.SecurityFilterChain;

import java.util.List;

/**
 * Seguridad unificada para toda la API HTTP bajo {@code /api/**} (bot + AGENDA).
 *
 * <p>Valida JWT (Google ID token) como Resource Server. Quedan públicos los webhooks
 * del bot, el registro/búsqueda pública de AGENDA y {@code POST /api/auth/google}.</p>
 *
 * <p>Rutas fuera de {@code /api/**} (p. ej. {@code /uploads/**}, Swagger UI) usan una
 * cadena aparte con {@code permitAll} para no romper estáticos y documentación.</p>
 */
@Configuration
@EnableWebSecurity
public class AgendaSecurityConfig {

    /**
     * API REST: mismo criterio de autenticación para panel del bot y AGENDA.
     */
    @Bean
    @Order(1)
    SecurityFilterChain apiSecurityFilterChain(
            HttpSecurity http,
            @Value("${agenda.security.enabled:true}") boolean enabled
    ) throws Exception {
        http.securityMatcher("/api/**");

        http.csrf(csrf -> csrf.disable());
        http.cors(Customizer.withDefaults());

        if (!enabled) {
            http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
            return http.build();
        }

        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(
                        "/api/agenda/public/**",
                        "/api/v1/webhook/**",
                        "/api/auth/google"
                ).permitAll()
                .anyRequest().authenticated()
        );

        http.oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));

        return http.build();
    }

    /**
     * Todo lo que no es {@code /api/**}: sin JWT (uploads, swagger, actuator, etc.).
     */
    @Bean
    @Order(2)
    SecurityFilterChain nonApiSecurityFilterChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/**");

        http.csrf(csrf -> csrf.disable());
        http.cors(Customizer.withDefaults());
        http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());

        return http.build();
    }

    @Bean
    JwtDecoder jwtDecoder(
            @Value("${agenda.security.google.issuer-uri:https://accounts.google.com}") String issuer,
            @Value("${agenda.security.google.audience:}") String audience
    ) {
        JwtDecoder decoder = JwtDecoders.fromIssuerLocation(issuer);
        if (decoder instanceof org.springframework.security.oauth2.jwt.NimbusJwtDecoder nimbus) {
            OAuth2TokenValidator<Jwt> withIssuer = JwtValidators.createDefaultWithIssuer(issuer);
            OAuth2TokenValidator<Jwt> validator = audience == null || audience.isBlank()
                    ? withIssuer
                    : new DelegatingOAuth2TokenValidator<>(withIssuer, new AudienceValidator(audience.trim()));
            nimbus.setJwtValidator(validator);
        }
        return decoder;
    }

    static final class AudienceValidator implements OAuth2TokenValidator<Jwt> {
        private final String audience;

        AudienceValidator(String audience) {
            this.audience = audience;
        }

        @Override
        public OAuth2TokenValidatorResult validate(Jwt token) {
            List<String> aud = token.getAudience();
            if (aud != null && aud.contains(audience)) {
                return OAuth2TokenValidatorResult.success();
            }
            return OAuth2TokenValidatorResult.failure(new OAuth2Error(
                    "invalid_token",
                    "El token no tiene el audience esperado.",
                    null
            ));
        }
    }
}


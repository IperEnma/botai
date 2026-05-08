package com.botai.agenda.infrastructure.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

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

    private static final Logger log = LoggerFactory.getLogger(AgendaSecurityConfig.class);

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

        http.oauth2ResourceServer(oauth2 -> oauth2
                .authenticationEntryPoint((request, response, ex) -> {
                    if (log.isDebugEnabled()) {
                        boolean hasAuth = request.getHeader("Authorization") != null
                                && !request.getHeader("Authorization").isBlank();
                        log.debug(
                                "AGENDA-SECURITY 401 | method={} uri={} hasAuthHeader={} ex={} msg={}",
                                request.getMethod(),
                                request.getRequestURI(),
                                hasAuth,
                                ex.getClass().getSimpleName(),
                                ex.getMessage()
                        );
                        Throwable cur = ex.getCause();
                        int depth = 0;
                        while (cur != null && depth < 6) {
                            log.debug("AGENDA-SECURITY 401 cause[{}]: {} msg={}",
                                    depth,
                                    cur.getClass().getSimpleName(),
                                    cur.getMessage());
                            cur = cur.getCause();
                            depth++;
                        }
                    }
                    new BearerTokenAuthenticationEntryPoint().commence(request, response, ex);
                })
                .jwt(Customizer.withDefaults()));

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
                    : new DelegatingOAuth2TokenValidator<>(withIssuer,
                            new AudienceValidator(parseAudienceList(audience)));
            nimbus.setJwtValidator(validator);
        }
        return decoder;
    }

    /**
     * Lista separada por comas o espacios (útil: cliente Web + Android + iOS en {@code GOOGLE_CLIENT_ID}).
     */
    static List<String> parseAudienceList(String raw) {
        return Arrays.stream(raw.split("[,\\s]+"))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    static final class AudienceValidator implements OAuth2TokenValidator<Jwt> {

        private final List<String> expectedAudiences;

        AudienceValidator(List<String> expectedAudiences) {
            this.expectedAudiences = List.copyOf(expectedAudiences);
        }

        @Override
        public OAuth2TokenValidatorResult validate(Jwt token) {
            if (expectedAudiences.isEmpty()) {
                return OAuth2TokenValidatorResult.success();
            }
            List<String> aud = token.getAudience();
            if (aud == null) {
                return OAuth2TokenValidatorResult.failure(new OAuth2Error(
                        "invalid_token",
                        "El token no declara audience (aud).",
                        null
                ));
            }
            for (String expected : expectedAudiences) {
                if (aud.contains(expected)) {
                    return OAuth2TokenValidatorResult.success();
                }
            }
            return OAuth2TokenValidatorResult.failure(new OAuth2Error(
                    "invalid_token",
                    "El token no coincide con ningún OAuth client ID configurado (audience). "
                            + "Tip: en Flutter Web el aud es GOOGLE_CLIENT_ID_WEB; en Android sin serverClientId, "
                            + "el aud es el cliente Android — añadilo a GOOGLE_CLIENT_ID separado por comas "
                            + "o configurá serverClientId al cliente Web.",
                    null
            ));
        }
    }
}


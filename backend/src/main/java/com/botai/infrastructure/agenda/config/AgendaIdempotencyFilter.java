package com.botai.infrastructure.agenda.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Garantiza idempotencia en POST /api/agenda/me/{tenant}/businesses/{biz}/bookings.
 *
 * El cliente envía el header {@code Idempotency-Key: <uuid>}. Si la clave ya
 * existe en {@code agenda_idempotency_keys} se devuelve la respuesta original
 * cacheada (status code + body) sin volver a ejecutar el caso de uso.
 * Si no existe, se ejecuta el request normal y se persiste la respuesta.
 * Si el header está ausente, el filtro pasa de largo (idempotencia opcional).
 */
@Component
public class AgendaIdempotencyFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(AgendaIdempotencyFilter.class);
    private static final String HEADER = "Idempotency-Key";

    private final JdbcTemplate jdbc;

    public AgendaIdempotencyFilter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !"POST".equalsIgnoreCase(request.getMethod())
                || !request.getRequestURI().matches(".*/api/agenda/me/.*/bookings$");
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String key = request.getHeader(HEADER);
        if (key == null || key.isBlank()) {
            filterChain.doFilter(request, response);
            return;
        }

        if (key.length() > 128) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Idempotency-Key no puede superar 128 caracteres");
            return;
        }

        var cached = findCached(key);
        if (cached != null) {
            log.debug("AGENDA idempotency: hit key={}", key);
            response.setStatus(cached.statusCode());
            response.setContentType("application/json");
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            byte[] bodyBytes = cached.body().getBytes(StandardCharsets.UTF_8);
            response.setContentLength(bodyBytes.length);
            response.getOutputStream().write(bodyBytes);
            return;
        }

        ContentCachingResponseWrapper wrapped = new ContentCachingResponseWrapper(response);
        filterChain.doFilter(request, wrapped);

        byte[] body = wrapped.getContentAsByteArray();
        String bodyStr = new String(body, wrapped.getCharacterEncoding());
        int status = wrapped.getStatus();

        if (status >= 200 && status < 300) {
            store(key, status, bodyStr);
        }

        wrapped.copyBodyToResponse();
    }

    private record CachedEntry(int statusCode, String body) {}

    private CachedEntry findCached(String key) {
        try {
            return jdbc.queryForObject(
                    "SELECT status_code, response_body FROM agenda_idempotency_keys WHERE idempotency_key = ?",
                    (rs, n) -> new CachedEntry(rs.getInt("status_code"), rs.getString("response_body")),
                    key);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            return null;
        }
    }

    private void store(String key, int statusCode, String body) {
        try {
            jdbc.update(
                    "INSERT INTO agenda_idempotency_keys (idempotency_key, status_code, response_body) " +
                    "VALUES (?, ?, ?) ON CONFLICT (idempotency_key) DO NOTHING",
                    key, statusCode, body);
        } catch (Exception ex) {
            log.warn("AGENDA idempotency: no se pudo persistir key={}", key, ex);
        }
    }
}

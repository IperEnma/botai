package com.botai.infrastructure.agenda.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.botai.infrastructure.agenda.support.HttpRequestClientIp;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Límite grueso por IP en OTP/sesión pública (complementa rate guard por teléfono en servicio).
 */
@Component
public class AgendaPhoneVerificationRateLimitInterceptor implements HandlerInterceptor {

    private final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();
    private final int requestsPerMinute;
    private final ObjectMapper objectMapper;

    public AgendaPhoneVerificationRateLimitInterceptor(
            @Value("${agenda.phone.verification.rate-limit.http-per-ip-per-minute:120}") int requestsPerMinute,
            ObjectMapper objectMapper) {
        this.requestsPerMinute = requestsPerMinute;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        String ip = HttpRequestClientIp.resolve(request);
        Bucket bucket = buckets.computeIfAbsent(ip, k -> newBucket());
        if (bucket.tryConsume(1)) {
            return true;
        }
        response.setStatus(429);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(Map.of(
                "code", "RATE_LIMIT_EXCEEDED",
                "message", "Demasiadas solicitudes. Intentá en unos segundos.")));
        return false;
    }

    private Bucket newBucket() {
        Bandwidth limit = Bandwidth.builder()
                .capacity(requestsPerMinute)
                .refillGreedy(requestsPerMinute, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }
}

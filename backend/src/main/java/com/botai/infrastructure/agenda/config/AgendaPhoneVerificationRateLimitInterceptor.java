package com.botai.infrastructure.agenda.config;

import com.botai.application.agenda.support.AgendaSecurityAuditService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.botai.infrastructure.agenda.support.HttpRequestClientIp;

import java.util.Map;

/**
 * Límite grueso por IP en OTP/sesión pública. Conteo en PostgreSQL (multi-instancia).
 */
@Component
public class AgendaPhoneVerificationRateLimitInterceptor implements HandlerInterceptor {

    private final AgendaSecurityAuditService audit;
    private final int requestsPerMinute;
    private final ObjectMapper objectMapper;

    public AgendaPhoneVerificationRateLimitInterceptor(
            AgendaSecurityAuditService audit,
            @Value("${agenda.phone.verification.rate-limit.http-per-ip-per-minute:120}") int requestsPerMinute,
            ObjectMapper objectMapper) {
        this.audit = audit;
        this.requestsPerMinute = requestsPerMinute;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        String ip = HttpRequestClientIp.resolve(request);
        AgendaSecurityAuditService.HttpRateCheck result =
                audit.checkAndRecordPublicHttpAccess(ip, requestsPerMinute);
        if (result == AgendaSecurityAuditService.HttpRateCheck.ALLOWED) {
            return true;
        }
        response.setStatus(429);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(Map.of(
                "code", "RATE_LIMIT_EXCEEDED",
                "message", "Demasiadas solicitudes. Intentá en unos segundos.")));
        return false;
    }
}

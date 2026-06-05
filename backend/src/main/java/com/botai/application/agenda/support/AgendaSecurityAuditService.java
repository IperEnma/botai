package com.botai.application.agenda.support;

import com.botai.infrastructure.agenda.persistence.entity.AgendaSecurityAuditEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaSecurityAuditJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Registro append-only de eventos de seguridad del flujo OTP/sesión pública.
 */
@Service
public class AgendaSecurityAuditService {

    private static final Logger log = LoggerFactory.getLogger(AgendaSecurityAuditService.class);

    public enum EventType {
        OTP_SEND,
        OTP_VERIFY_SUCCESS,
        OTP_VERIFY_FAIL,
        OTP_LOCKED,
        SESSION_ISSUED,
        SESSION_USED,
        SESSION_REJECTED,
        RATE_LIMITED
    }

    public enum Outcome {
        SUCCESS,
        FAIL,
        BLOCKED
    }

    private final AgendaSecurityAuditJpaRepository repository;
    private final AgendaSecurityHasher hasher;

    public AgendaSecurityAuditService(AgendaSecurityAuditJpaRepository repository,
                                      AgendaSecurityHasher hasher) {
        this.repository = repository;
        this.hasher = hasher;
    }

    @Transactional
    public void record(EventType type,
                       Outcome outcome,
                       String tenantId,
                       String clientIp,
                       String phoneNormalized,
                       String sessionToken,
                       String detail) {
        AgendaSecurityAuditEntity row = new AgendaSecurityAuditEntity();
        row.setEventType(type.name());
        row.setOutcome(outcome.name());
        row.setTenantId(tenantId);
        row.setClientIp(truncate(clientIp, 64));
        if (phoneNormalized != null && !phoneNormalized.isBlank()) {
            row.setPhoneHash(hasher.phoneKey(
                    tenantId != null ? tenantId : "",
                    phoneNormalized));
        }
        if (sessionToken != null && !sessionToken.isBlank()) {
            row.setTokenHash(hasher.hash(sessionToken.trim()));
        }
        row.setDetail(truncate(detail, 500));
        repository.save(row);
        if (log.isDebugEnabled()) {
            log.debug("AGENDA-SECURITY {} {} tenant={} ip={}",
                    type, outcome, tenantId, maskIp(clientIp));
        }
    }

    @Transactional(readOnly = true)
    public long countRecentByPhoneHash(String phoneHash, String eventType, java.time.LocalDateTime since) {
        return repository.countByPhoneHashAndEventTypeAndCreatedAtAfter(phoneHash, eventType, since);
    }

    @Transactional(readOnly = true)
    public long countRecentByIpAndEventType(String clientIp, String eventType, java.time.LocalDateTime since) {
        return repository.countByClientIpAndEventTypeAndCreatedAtAfter(clientIp, eventType, since);
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }

    private static String maskIp(String ip) {
        if (ip == null || ip.isBlank()) {
            return "-";
        }
        int dot = ip.lastIndexOf('.');
        return dot > 0 ? ip.substring(0, dot + 1) + "xxx" : "xxx";
    }
}

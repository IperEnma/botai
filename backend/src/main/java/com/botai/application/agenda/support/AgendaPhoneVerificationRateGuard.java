package com.botai.application.agenda.support;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Límites de abuso para envío y verificación OTP (conteo vía audit log + lockout en challenge).
 */
@Component
public class AgendaPhoneVerificationRateGuard {

    private final AgendaSecurityAuditService audit;
    private final AgendaSecurityHasher hasher;
    private final int sendPerPhonePerHour;
    private final int sendPerIpPerMinute;
    private final int verifyPerIpPerMinute;
    private final int maxFailedAttempts;
    private final int lockoutMinutes;

    public AgendaPhoneVerificationRateGuard(
            AgendaSecurityAuditService audit,
            AgendaSecurityHasher hasher,
            @Value("${agenda.phone.verification.rate-limit.send-per-phone-per-hour:5}") int sendPerPhonePerHour,
            @Value("${agenda.phone.verification.rate-limit.send-per-ip-per-minute:10}") int sendPerIpPerMinute,
            @Value("${agenda.phone.verification.rate-limit.verify-per-ip-per-minute:20}") int verifyPerIpPerMinute,
            @Value("${agenda.phone.verification.rate-limit.max-failed-attempts:5}") int maxFailedAttempts,
            @Value("${agenda.phone.verification.rate-limit.lockout-minutes:15}") int lockoutMinutes) {
        this.audit = audit;
        this.hasher = hasher;
        this.sendPerPhonePerHour = sendPerPhonePerHour;
        this.sendPerIpPerMinute = sendPerIpPerMinute;
        this.verifyPerIpPerMinute = verifyPerIpPerMinute;
        this.maxFailedAttempts = maxFailedAttempts;
        this.lockoutMinutes = lockoutMinutes;
    }

    public int maxFailedAttempts() {
        return maxFailedAttempts;
    }

    public int lockoutMinutes() {
        return lockoutMinutes;
    }

    public void assertCanSend(String tenantId, String phoneNormalized, String clientIp) {
        LocalDateTime sinceHour = LocalDateTime.now().minusHours(1);
        LocalDateTime sinceMinute = LocalDateTime.now().minusMinutes(1);
        String phoneHash = hasher.phoneKey(tenantId, phoneNormalized);
        String ip = normalizeIp(clientIp);

        long byPhone = audit.countRecentByPhoneHash(
                phoneHash, AgendaSecurityAuditService.EventType.OTP_SEND.name(), sinceHour);
        if (byPhone >= sendPerPhonePerHour) {
            audit.record(
                    AgendaSecurityAuditService.EventType.RATE_LIMITED,
                    AgendaSecurityAuditService.Outcome.BLOCKED,
                    tenantId, ip, phoneNormalized, null,
                    "OTP send limit per phone");
            throw new IllegalArgumentException(
                    "Demasiados códigos solicitados para este teléfono. Probá más tarde.");
        }

        long byIp = audit.countRecentByIpAndEventType(
                ip, AgendaSecurityAuditService.EventType.OTP_SEND.name(), sinceMinute);
        if (byIp >= sendPerIpPerMinute) {
            audit.record(
                    AgendaSecurityAuditService.EventType.RATE_LIMITED,
                    AgendaSecurityAuditService.Outcome.BLOCKED,
                    tenantId, ip, phoneNormalized, null,
                    "OTP send limit per IP");
            throw new IllegalArgumentException(
                    "Demasiadas solicitudes desde tu conexión. Esperá un momento.");
        }
    }

    public void assertCanVerify(String tenantId, String phoneNormalized, String clientIp) {
        String ip = normalizeIp(clientIp);
        LocalDateTime sinceMinute = LocalDateTime.now().minusMinutes(1);
        long verifyEvents = audit.countRecentByIpAndEventType(
                ip, AgendaSecurityAuditService.EventType.OTP_VERIFY_FAIL.name(), sinceMinute)
                + audit.countRecentByIpAndEventType(
                ip, AgendaSecurityAuditService.EventType.OTP_VERIFY_SUCCESS.name(), sinceMinute);
        if (verifyEvents >= verifyPerIpPerMinute) {
            audit.record(
                    AgendaSecurityAuditService.EventType.RATE_LIMITED,
                    AgendaSecurityAuditService.Outcome.BLOCKED,
                    tenantId, ip, phoneNormalized, null,
                    "OTP verify limit per IP");
            throw new IllegalArgumentException(
                    "Demasiados intentos de verificación. Esperá un momento.");
        }
    }

    static String normalizeIp(String clientIp) {
        if (clientIp == null || clientIp.isBlank()) {
            return "unknown";
        }
        return clientIp.trim();
    }
}

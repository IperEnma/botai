package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import com.botai.infrastructure.agenda.persistence.entity.AgendaClientSessionEntity;
import com.botai.infrastructure.agenda.persistence.entity.AgendaOtpChallengeEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaClientSessionJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaOtpChallengeJpaRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Sesión de cliente en agenda pública: teléfono verificado por OTP (WhatsApp).
 * Persistencia en PostgreSQL (multi-instancia) con hashes, rate limit y audit log.
 */
@Service
public class AgendaPublicClientSessionService {

    public static final String SESSION_HEADER = "X-Agenda-Client-Session";

    public record ClientSession(
            String tenantId,
            UUID userId,
            String phoneNormalized,
            long expiresAtEpochMs
    ) {}

    private final AgendaPhoneOtpService otpService;
    private final PhoneVerificationDeliveryPort deliveryPort;
    private final AgendaOtpChallengeJpaRepository otpRepository;
    private final AgendaClientSessionJpaRepository sessionRepository;
    private final AgendaSecurityHasher hasher;
    private final AgendaSecurityAuditService audit;
    private final AgendaPhoneVerificationRateGuard rateGuard;
    private final Clock clock;
    private final long sessionTtlMillis;

    public AgendaPublicClientSessionService(
            AgendaPhoneOtpService otpService,
            PhoneVerificationDeliveryPort deliveryPort,
            AgendaOtpChallengeJpaRepository otpRepository,
            AgendaClientSessionJpaRepository sessionRepository,
            AgendaSecurityHasher hasher,
            AgendaSecurityAuditService audit,
            AgendaPhoneVerificationRateGuard rateGuard,
            Clock clock,
            @Value("${agenda.phone.verification.session-minutes:15}") int sessionMinutes) {
        this.otpService = otpService;
        this.deliveryPort = deliveryPort;
        this.otpRepository = otpRepository;
        this.sessionRepository = sessionRepository;
        this.hasher = hasher;
        this.audit = audit;
        this.rateGuard = rateGuard;
        this.clock = clock;
        this.sessionTtlMillis = Math.max(1, sessionMinutes) * 60L * 1000L;
    }

    @Transactional
    public SendResult sendCode(String tenantId, String phoneNormalized, String clientIp) {
        rateGuard.assertCanSend(tenantId, phoneNormalized, clientIp);

        String code = otpService.generateCode();
        LocalDateTime expires = toLocalDateTime(otpService.expiryEpochMillis());
        String phoneHash = hasher.phoneKey(tenantId, phoneNormalized);

        otpRepository.findByTenantIdAndPhoneHash(tenantId, phoneHash).ifPresent(otpRepository::delete);

        AgendaOtpChallengeEntity challenge = new AgendaOtpChallengeEntity();
        challenge.setTenantId(tenantId);
        challenge.setPhoneHash(phoneHash);
        challenge.setCodeHash(hasher.hash(code));
        challenge.setExpiresAt(expires);
        challenge.setFailedAttempts(0);
        challenge.setLockedUntil(null);
        otpRepository.save(challenge);

        boolean delivered = deliveryPort.sendVerificationCode(tenantId, phoneNormalized, code);

        audit.record(
                AgendaSecurityAuditService.EventType.OTP_SEND,
                delivered ? AgendaSecurityAuditService.Outcome.SUCCESS : AgendaSecurityAuditService.Outcome.FAIL,
                tenantId,
                clientIp,
                phoneNormalized,
                null,
                delivered ? null : "WhatsApp delivery failed");

        return new SendResult(delivered);
    }

    @Transactional
    public String issueSessionToken(String tenantId, UUID userId, String phoneNormalized, String clientIp) {
        String token = UUID.randomUUID().toString();
        LocalDateTime expires = toLocalDateTime(clock.millis() + sessionTtlMillis);

        AgendaClientSessionEntity row = new AgendaClientSessionEntity();
        row.setTokenHash(hasher.hash(token));
        row.setTenantId(tenantId);
        row.setUserId(userId);
        row.setPhoneHash(hasher.phoneKey(tenantId, phoneNormalized));
        row.setPhoneNormalized(phoneNormalized);
        row.setExpiresAt(expires);
        sessionRepository.save(row);

        audit.record(
                AgendaSecurityAuditService.EventType.SESSION_ISSUED,
                AgendaSecurityAuditService.Outcome.SUCCESS,
                tenantId,
                clientIp,
                phoneNormalized,
                token,
                null);

        return token;
    }

    @Transactional(readOnly = true)
    public ClientSession requireSession(String token, String clientIp) {
        return loadSession(token, clientIp, null, true);
    }

    @Transactional(readOnly = true)
    public ClientSession requireSessionForTenant(String token, String tenantId, String clientIp) {
        return loadSession(token, clientIp, tenantId, true);
    }

    @Transactional
    public void recordSessionUsed(String token, String tenantId, String clientIp, String detail) {
        audit.record(
                AgendaSecurityAuditService.EventType.SESSION_USED,
                AgendaSecurityAuditService.Outcome.SUCCESS,
                tenantId,
                clientIp,
                null,
                token,
                detail);
    }

    @Transactional
    public void verifyOtpCode(String tenantId, String phoneNormalized, String userCode, String clientIp) {
        rateGuard.assertCanVerify(tenantId, phoneNormalized, clientIp);

        String phoneHash = hasher.phoneKey(tenantId, phoneNormalized);
        AgendaOtpChallengeEntity pending = otpRepository.findByTenantIdAndPhoneHash(tenantId, phoneHash)
                .orElseThrow(() -> {
                    audit.record(
                            AgendaSecurityAuditService.EventType.OTP_VERIFY_FAIL,
                            AgendaSecurityAuditService.Outcome.FAIL,
                            tenantId, clientIp, phoneNormalized, null,
                            "No pending challenge");
                    return new IllegalArgumentException(
                            "No hay código pendiente para este teléfono. Solicitá uno nuevo.");
                });

        LocalDateTime now = LocalDateTime.now(clock);
        if (pending.getLockedUntil() != null && pending.getLockedUntil().isAfter(now)) {
            audit.record(
                    AgendaSecurityAuditService.EventType.OTP_LOCKED,
                    AgendaSecurityAuditService.Outcome.BLOCKED,
                    tenantId, clientIp, phoneNormalized, null,
                    "Challenge locked");
            throw new IllegalArgumentException(
                    "Demasiados intentos fallidos. Probá más tarde o solicitá un código nuevo.");
        }

        if (pending.getExpiresAt().isBefore(now)) {
            otpRepository.delete(pending);
            audit.record(
                    AgendaSecurityAuditService.EventType.OTP_VERIFY_FAIL,
                    AgendaSecurityAuditService.Outcome.FAIL,
                    tenantId, clientIp, phoneNormalized, null,
                    "Code expired");
            throw new IllegalArgumentException("El código expiró. Solicitá uno nuevo.");
        }

        String parsedCode = AgendaPhoneOtpService.parseCode(userCode);
        if (parsedCode == null || !hasher.matches(parsedCode, pending.getCodeHash())) {
            int attempts = pending.getFailedAttempts() + 1;
            pending.setFailedAttempts(attempts);
            if (attempts >= rateGuard.maxFailedAttempts()) {
                pending.setLockedUntil(now.plusMinutes(rateGuard.lockoutMinutes()));
                audit.record(
                        AgendaSecurityAuditService.EventType.OTP_LOCKED,
                        AgendaSecurityAuditService.Outcome.BLOCKED,
                        tenantId, clientIp, phoneNormalized, null,
                        "Max failed attempts");
            }
            otpRepository.save(pending);
            audit.record(
                    AgendaSecurityAuditService.EventType.OTP_VERIFY_FAIL,
                    AgendaSecurityAuditService.Outcome.FAIL,
                    tenantId, clientIp, phoneNormalized, null,
                    "Wrong code");
            throw new IllegalArgumentException("Código incorrecto.");
        }

        otpRepository.delete(pending);
        audit.record(
                AgendaSecurityAuditService.EventType.OTP_VERIFY_SUCCESS,
                AgendaSecurityAuditService.Outcome.SUCCESS,
                tenantId, clientIp, phoneNormalized, null,
                null);
    }

    private ClientSession loadSession(String token, String clientIp, String expectedTenantId, boolean auditFailure) {
        if (token == null || token.isBlank()) {
            rejectSession(null, clientIp, expectedTenantId, "Missing token", auditFailure);
            throw new IllegalArgumentException("Iniciá sesión con tu teléfono y el código de WhatsApp.");
        }

        var rowOpt = sessionRepository.findByTokenHash(hasher.hash(token.trim()));
        if (rowOpt.isEmpty()) {
            rejectSession(token, clientIp, expectedTenantId, "Unknown token", auditFailure);
            throw new IllegalArgumentException("Sesión inválida o expirada. Verificá tu teléfono de nuevo.");
        }
        AgendaClientSessionEntity row = rowOpt.get();

        LocalDateTime now = LocalDateTime.now(clock);
        if (row.getExpiresAt().isBefore(now)) {
            sessionRepository.delete(row);
            rejectSession(token, clientIp, expectedTenantId, "Expired", auditFailure);
            throw new IllegalArgumentException("Sesión expirada. Verificá tu teléfono de nuevo.");
        }

        if (expectedTenantId != null && !expectedTenantId.equals(row.getTenantId())) {
            rejectSession(token, clientIp, expectedTenantId, "Tenant mismatch", auditFailure);
            throw new IllegalArgumentException("Sesión no válida para este negocio.");
        }

        return new ClientSession(
                row.getTenantId(),
                row.getUserId(),
                row.getPhoneNormalized(),
                row.getExpiresAt().atZone(clock.getZone()).toInstant().toEpochMilli());
    }

    private void rejectSession(String token, String clientIp, String tenantId, String detail, boolean auditFailure) {
        if (!auditFailure) {
            return;
        }
        audit.record(
                AgendaSecurityAuditService.EventType.SESSION_REJECTED,
                AgendaSecurityAuditService.Outcome.FAIL,
                tenantId,
                clientIp,
                null,
                token,
                detail);
    }

    private LocalDateTime toLocalDateTime(long epochMillis) {
        return LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(epochMillis), clock.getZone());
    }

    public record SendResult(boolean delivered) {}
}

package com.botai.infrastructure.agenda.config;

import com.botai.infrastructure.agenda.persistence.jpa.AgendaClientSessionJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaOtpChallengeJpaRepository;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaSecurityAuditJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Purga OTP/sesiones expiradas y audit log antiguo.
 */
@Component
public class AgendaPhoneVerificationCleanupScheduler {

    private static final Logger log = LoggerFactory.getLogger(AgendaPhoneVerificationCleanupScheduler.class);

    private final AgendaOtpChallengeJpaRepository otpRepository;
    private final AgendaClientSessionJpaRepository sessionRepository;
    private final AgendaSecurityAuditJpaRepository auditRepository;
    private final int auditRetentionDays;

    public AgendaPhoneVerificationCleanupScheduler(
            AgendaOtpChallengeJpaRepository otpRepository,
            AgendaClientSessionJpaRepository sessionRepository,
            AgendaSecurityAuditJpaRepository auditRepository,
            @Value("${agenda.phone.verification.audit-retention-days:90}") int auditRetentionDays) {
        this.otpRepository = otpRepository;
        this.sessionRepository = sessionRepository;
        this.auditRepository = auditRepository;
        this.auditRetentionDays = auditRetentionDays;
    }

    @Scheduled(cron = "${agenda.phone.verification.cleanup-cron:0 15 * * * *}")
    @Transactional
    public void purgeExpired() {
        LocalDateTime now = LocalDateTime.now();
        int otp = otpRepository.deleteExpired(now);
        int sessions = sessionRepository.deleteExpired(now);
        int audit = auditRepository.deleteOlderThan(now.minusDays(Math.max(1, auditRetentionDays)));
        if (otp + sessions + audit > 0 && log.isInfoEnabled()) {
            log.info("Agenda security cleanup: otp={} sessions={} audit={}", otp, sessions, audit);
        }
    }
}

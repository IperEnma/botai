package com.botai.application.agenda.support;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgendaPhoneVerificationRateGuardTest {

    @Mock
    AgendaSecurityAuditService audit;
    @Mock
    AgendaSecurityHasher hasher;

    AgendaPhoneVerificationRateGuard guard;

    @BeforeEach
    void setUp() {
        guard = new AgendaPhoneVerificationRateGuard(audit, hasher, 2, 2, 5, 3, 10);
        when(hasher.phoneKey("tenant-1", "59899123456")).thenReturn("phone-hash");
    }

    @Test
    void assertCanSend_blocksWhenPhoneLimitExceeded() {
        when(audit.countRecentByPhoneHash(eq("phone-hash"), eq("OTP_SEND"), any())).thenReturn(2L);
        assertThatThrownBy(() -> guard.assertCanSend("tenant-1", "59899123456", "1.2.3.4"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("teléfono");
    }

    @Test
    void assertCanSend_blocksWhenIpLimitExceeded() {
        when(audit.countRecentByPhoneHash(any(), any(), any())).thenReturn(0L);
        when(audit.countRecentByIpAndEventType(eq("1.2.3.4"), eq("OTP_SEND"), any())).thenReturn(2L);
        assertThatThrownBy(() -> guard.assertCanSend("tenant-1", "59899123456", "1.2.3.4"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("conexión");
    }
}

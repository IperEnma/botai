package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgendaPublicClientSessionServiceTest {

    PhoneVerificationDeliveryPort deliveryPort;
    AgendaPublicClientSessionService service;

    @BeforeEach
    void setUp() {
        deliveryPort = mock(PhoneVerificationDeliveryPort.class);
        service = new AgendaPublicClientSessionService(
            new AgendaPhoneOtpService(6, 10),
            deliveryPort,
            true,
            false,
            15);
    }

    @Test
    void verifyOtp_andIssueSession_succeeds() {
        when(deliveryPort.sendVerificationCode(anyString(), anyString(), anyString())).thenReturn(true);
        service.sendCode("tenant-1", "59899123456");
        ArgumentCaptor<String> codeCaptor = ArgumentCaptor.forClass(String.class);
        verify(deliveryPort).sendVerificationCode(eq("tenant-1"), eq("59899123456"), codeCaptor.capture());
        service.verifyOtpCode("tenant-1", "59899123456", codeCaptor.getValue());
        UUID userId = UUID.randomUUID();
        String token = service.issueSessionToken("tenant-1", userId, "59899123456");
        assertThat(token).isNotBlank();
        var session = service.requireSessionForTenant(token, "tenant-1");
        assertThat(session.userId()).isEqualTo(userId);
        assertThat(session.phoneNormalized()).isEqualTo("59899123456");
    }

    @Test
    void verifyOtp_skippedWhenDisabled() {
        AgendaPublicClientSessionService disabled = new AgendaPublicClientSessionService(
            new AgendaPhoneOtpService(6, 10), deliveryPort, false, false, 15);
        disabled.verifyOtpCode("tenant-1", "59899123456", "000000");
    }

    @Test
    void verifyOtp_wrongCodeThrows() {
        when(deliveryPort.sendVerificationCode(anyString(), anyString(), anyString())).thenReturn(true);
        service.sendCode("tenant-1", "59899123456");
        assertThatThrownBy(() -> service.verifyOtpCode("tenant-1", "59899123456", "000000"))
            .isInstanceOf(IllegalArgumentException.class);
    }
}

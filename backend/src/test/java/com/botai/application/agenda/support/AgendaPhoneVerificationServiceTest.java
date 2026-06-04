package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgendaPhoneVerificationServiceTest {

    PhoneVerificationDeliveryPort deliveryPort;
    AgendaPhoneVerificationService service;

    @BeforeEach
    void setUp() {
        deliveryPort = mock(PhoneVerificationDeliveryPort.class);
        service = new AgendaPhoneVerificationService(
            new AgendaPhoneOtpService(6, 10),
            deliveryPort,
            true,
            false);
    }

    @Test
    void verifyAndIssueToken_afterSend_succeeds() {
        when(deliveryPort.sendVerificationCode(anyString(), anyString(), anyString())).thenReturn(true);
        service.sendCode("tenant-1", "59899123456");
        ArgumentCaptor<String> codeCaptor = ArgumentCaptor.forClass(String.class);
        verify(deliveryPort).sendVerificationCode(eq("tenant-1"), eq("59899123456"), codeCaptor.capture());
        String token = service.verifyAndIssueToken("tenant-1", "59899123456", codeCaptor.getValue());
        assertThat(token).isNotBlank();
        service.assertValidToken("tenant-1", "59899123456", token);
    }

    @Test
    void assertValidToken_skippedWhenDisabled() {
        AgendaPhoneVerificationService disabled = new AgendaPhoneVerificationService(
            new AgendaPhoneOtpService(6, 10), deliveryPort, false, false);
        disabled.assertValidToken("tenant-1", "59899123456", null);
    }

    @Test
    void verify_wrongCodeThrows() {
        when(deliveryPort.sendVerificationCode(anyString(), anyString(), anyString())).thenReturn(true);
        service.sendCode("tenant-1", "59899123456");
        assertThatThrownBy(() -> service.verifyAndIssueToken("tenant-1", "59899123456", "000000"))
            .isInstanceOf(IllegalArgumentException.class);
    }
}

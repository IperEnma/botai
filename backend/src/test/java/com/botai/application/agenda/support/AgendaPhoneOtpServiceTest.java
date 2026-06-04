package com.botai.application.agenda.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AgendaPhoneOtpServiceTest {

    private final AgendaPhoneOtpService service = new AgendaPhoneOtpService(6, 10);

    @Test
    void generateCode_isSixDigits() {
        String code = service.generateCode();
        assertThat(code).matches("\\d{6}");
    }

    @Test
    void matches_acceptsSpacedInput() {
        assertThat(service.matches("123456", "123 456")).isTrue();
    }

    @Test
    void matches_rejectsWrongCode() {
        assertThat(service.matches("123456", "654321")).isFalse();
    }

    @Test
    void isExpired_detectsPast() {
        long past = System.currentTimeMillis() - 1;
        assertThat(service.isExpired(past)).isTrue();
    }
}

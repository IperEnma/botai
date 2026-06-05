package com.botai.infrastructure.agenda.config;

import com.botai.application.agenda.support.AgendaSecurityHasher;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AgendaPhoneVerificationStartupValidatorTest {

    @Test
    void prodProfile_failsWhenDevPepper() {
        AgendaSecurityHasher hasher = mock(AgendaSecurityHasher.class);
        when(hasher.isDevPepper()).thenReturn(true);
        var validator = new AgendaPhoneVerificationStartupValidator(
                true, hasher, "prod", "https://api.example.com", "https://app.example.com");
        assertThatThrownBy(() -> validator.onApplicationEvent(null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hash-pepper");
    }

    @Test
    void prodProfile_failsWhenPublicUrlsNotHttps() {
        AgendaSecurityHasher hasher = mock(AgendaSecurityHasher.class);
        when(hasher.isDevPepper()).thenReturn(false);
        var validator = new AgendaPhoneVerificationStartupValidator(
                true, hasher, "prod", "http://api.example.com", "https://app.example.com");
        assertThatThrownBy(() -> validator.onApplicationEvent(null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("HTTPS");
    }
}

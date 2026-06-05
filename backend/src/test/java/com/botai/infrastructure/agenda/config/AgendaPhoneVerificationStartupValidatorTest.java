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
                true, hasher, "prod");
        assertThatThrownBy(() -> validator.onApplicationEvent(null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hash-pepper");
    }
}

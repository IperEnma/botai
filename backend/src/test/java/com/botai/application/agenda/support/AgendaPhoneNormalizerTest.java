package com.botai.application.agenda.support;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AgendaPhoneNormalizerTest {

    @BeforeEach
    void uruguayDefault() {
        AgendaPhoneNormalizer.configureDefaultCountryCode("598");
    }

    @Test
    void normalize_localUruguayWithLeadingZero() {
        assertThat(AgendaPhoneNormalizer.normalize("099 123 456")).isEqualTo("59899123456");
    }

    @Test
    void normalize_alreadyInternational() {
        assertThat(AgendaPhoneNormalizer.normalize("+598 99 123 456")).isEqualTo("59899123456");
    }

    @Test
    void normalize_whatsappUserId() {
        assertThat(AgendaPhoneNormalizer.normalize("59899123456")).isEqualTo("59899123456");
    }

    @Test
    void matchCandidates_includesLegacyLocalForms() {
        assertThat(AgendaPhoneNormalizer.matchCandidates("59899123456"))
            .contains("59899123456", "099123456", "99123456");
    }

    @Test
    void phonesMatch_localVsInternationalUruguay() {
        assertThat(AgendaPhoneNormalizer.phonesMatch("097205089", "59897205089")).isTrue();
        assertThat(AgendaPhoneNormalizer.phonesMatch("59897205089", "097205089")).isTrue();
    }

    @Test
    void digitsOnly_stripsPlusAndSpaces() {
        assertThat(AgendaPhoneNormalizer.digitsOnly("+598 99-123-456")).isEqualTo("59899123456");
    }
}

package com.botai.application.agenda.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AgendaSecurityHasherTest {

    @Test
    void hash_isDeterministicAndPepperDependent() {
        AgendaSecurityHasher a = new AgendaSecurityHasher("pepper-a");
        AgendaSecurityHasher b = new AgendaSecurityHasher("pepper-b");
        assertThat(a.hash("59899123456")).isEqualTo(a.hash("59899123456"));
        assertThat(a.hash("59899123456")).isNotEqualTo(b.hash("59899123456"));
    }

    @Test
    void matches_acceptsSameValue() {
        AgendaSecurityHasher hasher = new AgendaSecurityHasher("test");
        String code = "123456";
        String stored = hasher.hash(code);
        assertThat(hasher.matches(code, stored)).isTrue();
        assertThat(hasher.matches("000000", stored)).isFalse();
    }

    @Test
    void isDevPepper_detectsDefault() {
        assertThat(new AgendaSecurityHasher(AgendaSecurityHasher.DEV_PEPPER).isDevPepper()).isTrue();
        assertThat(new AgendaSecurityHasher("prod-secret-pepper").isDevPepper()).isFalse();
    }
}

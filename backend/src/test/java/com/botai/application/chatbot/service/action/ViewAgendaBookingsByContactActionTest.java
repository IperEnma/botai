package com.botai.application.chatbot.service.action;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ViewAgendaBookingsByContactActionTest {

    @Test
    void tryParseContact_extractsEmail() {
        ViewAgendaBookingsByContactAction.Contact c =
            ViewAgendaBookingsByContactAction.tryParseContact("Hola, mi mail es ana@test.com gracias");
        assertThat(c).isNotNull();
        assertThat(c.email).isEqualTo("ana@test.com");
        assertThat(c.phoneNormalized).isNull();
    }

    @Test
    void tryParseContact_extractsPhoneDigits() {
        ViewAgendaBookingsByContactAction.Contact c =
            ViewAgendaBookingsByContactAction.tryParseContact("099 123 456");
        assertThat(c).isNotNull();
        assertThat(c.email).isNull();
        assertThat(c.phoneNormalized).isEqualTo("099123456");
    }

    @Test
    void tryParseContact_emailWinsWhenBothPresent() {
        ViewAgendaBookingsByContactAction.Contact c =
            ViewAgendaBookingsByContactAction.tryParseContact("099123456 y también x@y.com");
        assertThat(c).isNotNull();
        assertThat(c.email).isEqualTo("x@y.com");
    }
}

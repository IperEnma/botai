package com.botai.application.chatbot.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class BookingUrlSanitizerTest {

    @Test
    void detectsCalendly() {
        String msg = "Agendá acá: https://calendly.com/soluciones-energeticas-c0151b81";
        assertThat(BookingUrlSanitizer.containsBlockedThirdPartyBookingUrl(msg)).isTrue();
        assertThat(BookingUrlSanitizer.containsUrlOutsideAllowedHost(msg, "mi-app.vercel.app")).isTrue();
    }

    @Test
    void allowsOwnFrontendHost() {
        String msg = "Entrá: https://mi-app.vercel.app/#/reservar/slug";
        assertThat(BookingUrlSanitizer.containsUrlOutsideAllowedHost(msg, "mi-app.vercel.app")).isFalse();
    }
}

package com.botai.application.chatbot.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class InboundTextHeuristicsTest {

    @Test
    void looksLikeNewBookingRequest_agendarTypo() {
        assertThat(InboundTextHeuristics.looksLikeNewBookingRequest("Quiero agendar una ciga")).isTrue();
    }

    @Test
    void looksLikeNewBookingRequest_linkAgenda() {
        assertThat(InboundTextHeuristics.looksLikeNewBookingRequest("Pasame el link para reservar")).isTrue();
    }

    @Test
    void looksLikeNewBookingRequest_horarioInformativo_false() {
        assertThat(InboundTextHeuristics.looksLikeNewBookingRequest("¿A qué hora abren el lunes?")).isFalse();
    }

    @Test
    void looksLikeViewAgendaBookings_misCitas() {
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("Quiero ver mis citas")).isTrue();
    }

}

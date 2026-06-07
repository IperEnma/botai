package com.botai.application.chatbot.support;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class InboundTextHeuristicsTest {

    @Test
    void looksLikeNewBookingRequest_agendarTypo() {
        assertThat(InboundTextHeuristics.looksLikeNewBookingRequest("Quiero agendar una ciga")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeNewBookingRequest("Quiero agendsr")).isTrue();
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

    @Test
    void looksLikeViewAgendaBookings_agendasPendientes() {
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings(
            "Quiero saber si tengo agendas pendientes")).isTrue();
    }

    @Test
    void looksLikeViewAgendaBookings_horarioInformativo_false() {
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("¿A qué hora abren el lunes?")).isFalse();
    }

    @Test
    void looksLikeViewAgendaBookings_quedoConfirmado() {
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("Quedo confirmado?")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("¿Quedó confirmada mi cita?")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("Estado de mi reserva")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("Se confinó mi cita?")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeViewAgendaBookings("Cuáles son los citas pendiente?")).isTrue();
    }

    @Test
    void looksLikeGreetingOnly_hola() {
        assertThat(InboundTextHeuristics.looksLikeGreetingOnly("Hola")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeGreetingOnly("Buenos días!")).isTrue();
    }

    @Test
    void looksLikeGreetingOnly_conPregunta_false() {
        assertThat(InboundTextHeuristics.looksLikeGreetingOnly("Hola, quienes son")).isFalse();
        assertThat(InboundTextHeuristics.looksLikeGreetingOnly("Que ofrecen?")).isFalse();
    }

}

package com.botai.application.chatbot.service.feedback;

import com.botai.application.chatbot.support.InboundTextHeuristics;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ConversationFeedbackHeuristicsTest {

    @Test
    void detectsConversationClosing() {
        assertThat(InboundTextHeuristics.looksLikeConversationClosing("Gracias")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeConversationClosing("Listo, chau")).isTrue();
        assertThat(InboundTextHeuristics.looksLikeConversationClosing("Gracias, ¿cuál es el horario?")).isFalse();
    }

    @Test
    void parsesYesNoFeedback() {
        assertThat(InboundTextHeuristics.parseFeedbackYesNo("Sí")).contains(true);
        assertThat(InboundTextHeuristics.parseFeedbackYesNo("no")).contains(false);
        assertThat(InboundTextHeuristics.parseFeedbackYesNo("tal vez")).isEmpty();
    }
}

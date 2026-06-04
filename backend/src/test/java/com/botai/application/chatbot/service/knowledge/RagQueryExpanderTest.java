package com.botai.application.chatbot.service.knowledge;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RagQueryExpanderTest {

    @Test
    void buildRetrievalQuery_includesHistoryAndCurrentMessage() {
        String q = RagQueryExpander.buildRetrievalQuery(
                "¿y el domingo?",
                List.of("user: horarios", "assistant: Atendemos de lunes a viernes"),
                2);
        assertThat(q).contains("horarios");
        assertThat(q).contains("domingo");
    }

    @Test
    void buildRetrievalQuery_onlyCurrentWhenNoHistory() {
        assertThat(RagQueryExpander.buildRetrievalQuery("precios", List.of(), 2))
                .isEqualTo("precios");
    }
}

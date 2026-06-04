package com.botai.application.chatbot.service.knowledge;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RagTopicHintServiceTest {

    @Test
    void topicPrefixesForQuery_hours() {
        assertThat(RagTopicHintService.topicPrefixesForQuery("¿A qué hora abren el sábado?"))
                .contains(RagTopicHintService.TOPIC_HORARIOS);
    }

    @Test
    void topicPrefixesForQuery_services() {
        assertThat(RagTopicHintService.topicPrefixesForQuery("precio del corte de pelo"))
                .contains(RagTopicHintService.TOPIC_SERVICIOS);
    }

    @Test
    void topicPrefixesForQuery_emptyForGreeting() {
        assertThat(RagTopicHintService.topicPrefixesForQuery("hola")).isEmpty();
    }
}

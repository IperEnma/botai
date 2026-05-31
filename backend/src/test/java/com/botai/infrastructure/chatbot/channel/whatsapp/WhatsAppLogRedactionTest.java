package com.botai.infrastructure.chatbot.channel.whatsapp;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class WhatsAppLogRedactionTest {

    @Test
    void maskPhone_showsLastFourDigitsOnly() {
        assertThat(WhatsAppLogRedaction.maskPhone("59897205089")).isEqualTo("***5089");
    }

    @Test
    void summarizeWebhook_doesNotExposeFullPayload() {
        Map<String, Object> payload = Map.of(
                "entry", List.of(Map.of(
                        "changes", List.of(Map.of(
                                "value", Map.of(
                                        "statuses", List.of(Map.of("status", "delivered")),
                                        "metadata", Map.of("phone_number_id", "1092835880584272")
                                )
                        ))
                ))
        );

        String summary = WhatsAppLogRedaction.summarizeWebhook(payload);

        assertThat(summary).isEqualTo("status update: delivered");
        assertThat(summary).doesNotContain("1092835880584272");
    }
}

package com.botai.infrastructure.chatbot.persistence.entity;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BotEntityJsonTest {

    private final ObjectMapper mapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void deserializesWhatsappAccessTokenFromRequestBody() throws Exception {
        BotEntity bot = mapper.readValue(
                """
                {"name":"Bot1","whatsappAccessToken":"EAAtest-token"}
                """,
                BotEntity.class);

        assertEquals("EAAtest-token", bot.getWhatsappAccessToken());
    }

    @Test
    void doesNotSerializeWhatsappAccessTokenInResponse() throws Exception {
        BotEntity bot = new BotEntity();
        bot.setName("Bot1");
        bot.setWhatsappAccessToken("enc:v1:secret");

        String json = mapper.writeValueAsString(bot);

        assertFalse(json.contains("\"whatsappAccessToken\""));
        assertFalse(json.contains("enc:v1:secret"));
    }

    @Test
    void exposesConfiguredFlagWithoutTokenValue() throws Exception {
        BotEntity bot = new BotEntity();
        bot.setWhatsappAccessToken("enc:v1:secret");

        String json = mapper.writeValueAsString(bot);

        assertTrue(json.contains("whatsappAccessTokenConfigured"));
        assertTrue(bot.isWhatsappAccessTokenConfigured());
    }

    @Test
    void emptyAccessTokenDeserializesAsNullOrBlank() throws Exception {
        BotEntity bot = mapper.readValue(
                """
                {"name":"Bot1","whatsappAccessToken":""}
                """,
                BotEntity.class);

        assertTrue(bot.getWhatsappAccessToken() == null || bot.getWhatsappAccessToken().isBlank());
        assertFalse(bot.isWhatsappAccessTokenConfigured());
    }
}

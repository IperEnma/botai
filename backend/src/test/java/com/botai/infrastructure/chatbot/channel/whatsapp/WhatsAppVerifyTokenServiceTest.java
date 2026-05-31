package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.infrastructure.chatbot.config.BotWhatsAppConfig;
import com.botai.infrastructure.config.AppUrlProperties;
import com.botai.infrastructure.chatbot.persistence.jpa.BotJpaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WhatsAppVerifyTokenServiceTest {

    @Mock
    BotJpaRepository botRepository;

    BotWhatsAppConfig config;
    WhatsAppVerifyTokenService service;

    @BeforeEach
    void setUp() {
        config = new BotWhatsAppConfig(new AppUrlProperties());
        config.setVerifySecret("test-secret-at-least-16-chars");
        service = new WhatsAppVerifyTokenService(botRepository, config);
    }

    @Test
    void tokenForBot_isDeterministicAndDistinctPerBot() {
        when(botRepository.existsById(1L)).thenReturn(true);

        String t1 = service.tokenForBot(1L);
        String t2 = service.tokenForBot(2L);

        assertTrue(t1.startsWith("1."));
        assertTrue(t2.startsWith("2."));
        assertNotEquals(t1, t2);
        assertTrue(service.accepts(t1));
    }

    @Test
    void accepts_rejectsUnknownToken() {
        when(botRepository.existsById(5L)).thenReturn(true);
        String valid = service.tokenForBot(5L);

        assertTrue(service.accepts(valid));
        assertFalse(service.accepts(valid + "x"));
        assertFalse(service.accepts("5.invalid"));
    }

    @Test
    void accepts_legacyGlobalWhenConfigured() {
        config.setVerifyToken("legacy-global");
        assertTrue(service.accepts("legacy-global"));
    }
}

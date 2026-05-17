package com.botai.infrastructure.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DatabaseUrlEnvironmentPostProcessorTest {

    @Test
    void prependsJdbcToPostgresqlUrl() {
        String neon = "postgresql://user:pass@host.neon.tech/neondb?sslmode=require";
        assertEquals("jdbc:" + neon, DatabaseUrlEnvironmentPostProcessor.toJdbcUrl(neon));
    }

    @Test
    void leavesJdbcUrlUnchanged() {
        String jdbc = "jdbc:postgresql://localhost:5432/chatbot";
        assertEquals(jdbc, DatabaseUrlEnvironmentPostProcessor.toJdbcUrl(jdbc));
    }
}

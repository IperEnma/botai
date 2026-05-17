package com.botai.infrastructure.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class DatabaseUrlEnvironmentPostProcessorTest {

    @Test
    void splitsNeonUrlAndStripsChannelBinding() {
        String neon = "postgresql://neondb_owner:secret@ep-icy-sky-pooler.us-east-1.aws.neon.tech/neondb"
                + "?sslmode=require&channel_binding=require";

        DatabaseUrlEnvironmentPostProcessor.Normalized n =
                DatabaseUrlEnvironmentPostProcessor.normalize(neon);

        assertEquals("neondb_owner", n.username());
        assertEquals("secret", n.password());
        assertEquals(
                "jdbc:postgresql://ep-icy-sky-pooler.us-east-1.aws.neon.tech:5432/neondb?sslmode=require",
                n.jdbcUrl());
    }

    @Test
    void prependsJdbcWhenNoCredentialsInUrl() {
        String url = "postgresql://localhost:5444/chatbot";
        DatabaseUrlEnvironmentPostProcessor.Normalized n =
                DatabaseUrlEnvironmentPostProcessor.normalize(url);

        assertNull(n.username());
        assertEquals("jdbc:postgresql://localhost:5444/chatbot", n.jdbcUrl());
    }

    @Test
    void leavesLocalJdbcUrlWithoutAtSign() {
        String jdbc = "jdbc:postgresql://localhost:5432/chatbot";
        DatabaseUrlEnvironmentPostProcessor.Normalized n =
                DatabaseUrlEnvironmentPostProcessor.normalize(jdbc);

        assertNull(n.username());
        assertEquals(jdbc, n.jdbcUrl());
    }

    @Test
    void decodesUrlEncodedPassword() {
        String url = "postgresql://user:p%40ss%2Fw%3Drd@db.example.com:5432/mydb?sslmode=require";
        DatabaseUrlEnvironmentPostProcessor.Normalized n =
                DatabaseUrlEnvironmentPostProcessor.normalize(url);

        assertEquals("user", n.username());
        assertEquals("p@ss/w=rd", n.password());
        assertEquals("jdbc:postgresql://db.example.com:5432/mydb?sslmode=require", n.jdbcUrl());
    }
}

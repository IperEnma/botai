package com.botai.infrastructure.chatbot.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Log de arranque cuando {@code bot.embedding.provider=api} (cualquier API OpenAI-compatible:
 * OpenRouter, OpenAI, Ollama en {@code BOT_EMBEDDING_API_BASE_URL}, etc.).
 */
@Configuration
@ConditionalOnProperty(name = "bot.embedding.provider", havingValue = "api")
public class ApiEmbeddingStartupLogger {

    private static final Logger log = LoggerFactory.getLogger(ApiEmbeddingStartupLogger.class);

    @Bean
    ApplicationRunner apiEmbeddingStartupRunner(
            @Value("${spring.ai.openai.base-url}") String baseUrl,
            @Value("${spring.ai.openai.embedding.options.model}") String model) {
        return (ApplicationArguments args) -> log.info(
                "[EMBED-API] Embeddings RAG por HTTPS: baseUrl={} model={} (columna knowledge_chunk.embedding debe coincidir en dimensiones)",
                baseUrl,
                model);
    }
}

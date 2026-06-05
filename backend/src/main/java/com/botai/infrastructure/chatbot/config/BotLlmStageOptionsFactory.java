package com.botai.infrastructure.chatbot.config;

import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.stereotype.Component;

/**
 * Temperaturas por etapa del pipeline ({@code bot.llm.temperature.*}).
 */
@Component
public class BotLlmStageOptionsFactory {

    private final BotProperties botProperties;

    public BotLlmStageOptionsFactory(BotProperties botProperties) {
        this.botProperties = botProperties;
    }

    public ChatOptions forClassifier() {
        return temperature(botProperties.getLlm().getTemperature().getClassifier());
    }

    public ChatOptions forRagReply() {
        return temperature(botProperties.getLlm().getTemperature().getRagReply());
    }

    public ChatOptions forSelfReview() {
        return temperature(botProperties.getLlm().getTemperature().getSelfReview());
    }

    private static ChatOptions temperature(double temp) {
        return OllamaOptions.builder().temperature(temp).build();
    }
}

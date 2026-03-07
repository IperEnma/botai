package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.domain.service.LanguageModel;
import com.botai.chatbot.infrastructure.ai.SpringAiLanguageModel;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.ollama.api.OllamaApi;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Define ChatModel (Ollama) y LanguageModel en el mismo sitio para que el orden de creación no falle.
 * Usa spring.ai.ollama.base-url y spring.ai.ollama.chat.options.model.
 */
@Configuration
public class OllamaModelConfig {

    @Bean
    public ChatModel chatModel(
            @Value("${spring.ai.ollama.base-url:http://localhost:11434}") String baseUrl,
            @Value("${spring.ai.ollama.chat.options.model:qwen2.5:14b-instruct-q4_K_M}") String model) {
        OllamaApi api = OllamaApi.builder()
                .baseUrl(baseUrl)
                .build();
        OllamaOptions options = OllamaOptions.builder()
                .model(model)
                .build();
        return OllamaChatModel.builder()
                .ollamaApi(api)
                .defaultOptions(options)
                .build();
    }

    @Bean
    public LanguageModel languageModel(ChatModel chatModel) {
        return new SpringAiLanguageModel(chatModel);
    }
}

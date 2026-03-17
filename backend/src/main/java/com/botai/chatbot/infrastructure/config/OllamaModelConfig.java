package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.domain.service.LanguageModel;
import com.botai.chatbot.infrastructure.ai.SpringAiLanguageModel;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.ollama.OllamaEmbeddingModel;
import org.springframework.ai.ollama.api.OllamaApi;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Define ChatModel, EmbeddingModel (Ollama) y LanguageModel.
 * EmbeddingModel es obligatorio para RAG: sin él los chunks no se indexan y la búsqueda semántica devuelve 0.
 */
@Configuration
public class OllamaModelConfig {

    @Bean
    public OllamaApi ollamaApi(@Value("${spring.ai.ollama.base-url:http://localhost:11434}") String baseUrl) {
        return OllamaApi.builder().baseUrl(baseUrl).build();
    }

    @Bean
    public ChatModel chatModel(OllamaApi ollamaApi,
            @Value("${spring.ai.ollama.chat.options.model:qwen2.5:14b-instruct-q4_K_M}") String model) {
        OllamaOptions options = OllamaOptions.builder().model(model).build();
        return OllamaChatModel.builder()
                .ollamaApi(ollamaApi)
                .defaultOptions(options)
                .build();
    }

    @Bean
    public EmbeddingModel embeddingModel(OllamaApi ollamaApi,
            @Value("${spring.ai.ollama.embedding.options.model:nomic-embed-text}") String embeddingModelName) {
        OllamaOptions options = OllamaOptions.builder().model(embeddingModelName).build();
        return OllamaEmbeddingModel.builder()
                .ollamaApi(ollamaApi)
                .defaultOptions(options)
                .build();
    }

    @Bean
    public LanguageModel languageModel(ChatModel chatModel) {
        return new SpringAiLanguageModel(chatModel);
    }
}

package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.domain.service.LanguageModel;
import com.botai.chatbot.infrastructure.ai.SpringAiLanguageModel;
import com.botai.chatbot.infrastructure.http.HttpMessageConvertersUtf8;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.ollama.OllamaEmbeddingModel;
import org.springframework.ai.ollama.api.OllamaApi;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Define ChatModel, EmbeddingModel (Ollama, si {@code bot.embedding.provider=ollama}) y LanguageModel.
 * Con {@code bot.embedding.provider=djl} el {@link EmbeddingModel} lo registra {@link DjlEmbeddingConfig}.
 */
@Configuration
public class OllamaModelConfig {

    @Bean
    public OllamaApi ollamaApi(@Value("${spring.ai.ollama.base-url:http://localhost:11434}") String baseUrl) {
        RestClient.Builder restClientBuilder = RestClient.builder()
            .messageConverters(HttpMessageConvertersUtf8::applyTo);
        // OllamaApi usa WebClient para streaming; codecs por defecto de Spring 6 usan UTF-8 en JSON; subimos límite de buffer.
        WebClient.Builder webClientBuilder = WebClient.builder()
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(16 * 1024 * 1024));
        return OllamaApi.builder()
            .baseUrl(baseUrl)
            .restClientBuilder(restClientBuilder)
            .webClientBuilder(webClientBuilder)
            .build();
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
    @ConditionalOnProperty(name = "bot.embedding.provider", havingValue = "ollama", matchIfMissing = true)
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

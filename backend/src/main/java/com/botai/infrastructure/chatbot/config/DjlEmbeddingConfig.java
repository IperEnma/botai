package com.botai.infrastructure.chatbot.config;

import ai.djl.ModelException;
import com.botai.infrastructure.chatbot.ai.djl.DjlEmbeddingModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.io.IOException;

/**
 * Embeddings vía DJL (Hugging Face en JVM). Activo con {@code bot.embedding.provider=djl}.
 * Requiere {@code bot.embedding.provider=djl} y {@code spring.ai.model.embedding=none} (ver {@code application.yml}).
 */
@Configuration
@ConditionalOnProperty(name = "bot.embedding.provider", havingValue = "djl")
public class DjlEmbeddingConfig {

    private static final Logger log = LoggerFactory.getLogger(DjlEmbeddingConfig.class);

    @Bean(destroyMethod = "close")
    @Primary
    public EmbeddingModel embeddingModel(
            @Value("${bot.embedding.djl.model-url:djl://ai.djl.huggingface.pytorch/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2}") String modelUrl)
        throws ModelException, IOException {
        log.info("[DJL-EMBED] Registrando EmbeddingModel DJL (MiniLM multilingüe típico: 384 dims → alinear knowledge_chunk.embedding)");
        return new DjlEmbeddingModel(modelUrl);
    }
}

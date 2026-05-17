package com.botai.infrastructure.chatbot.ai.djl;

import ai.djl.ModelException;
import ai.djl.inference.Predictor;
import ai.djl.huggingface.translator.TextEmbeddingTranslatorFactory;
import ai.djl.repository.zoo.Criteria;
import ai.djl.repository.zoo.ZooModel;
import ai.djl.translate.TranslateException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.AbstractEmbeddingModel;
import org.springframework.ai.embedding.Embedding;
import org.springframework.ai.embedding.EmbeddingRequest;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Embeddings locales con DJL + PyTorch + modelo Hugging Face (p. ej. paraphrase-multilingual-MiniLM-L12-v2).
 * No pasa por Ollama; la dimensión del vector debe coincidir con {@code knowledge_chunk.embedding_384} en PostgreSQL.
 */
public class DjlEmbeddingModel extends AbstractEmbeddingModel {

    private static final Logger log = LoggerFactory.getLogger(DjlEmbeddingModel.class);
    private static final int MAX_CACHE_ENTRIES = 512;

    private final ZooModel<String, float[]> model;
    private final Predictor<String, float[]> predictor;
    private final Map<String, float[]> cache = new ConcurrentHashMap<>();
    private final Object predictLock = new Object();

    public DjlEmbeddingModel(String modelUrl) throws ModelException, IOException {
        Criteria<String, float[]> criteria = Criteria.builder()
            .setTypes(String.class, float[].class)
            .optModelUrls(modelUrl)
            .optEngine("PyTorch")
            .optTranslatorFactory(new TextEmbeddingTranslatorFactory())
            .build();
        this.model = criteria.loadModel();
        this.predictor = model.newPredictor();
        log.info("[DJL-EMBED] Modelo cargado: {}", modelUrl);
    }

    @Override
    public EmbeddingResponse call(EmbeddingRequest request) {
        List<String> inputs = request.getInstructions();
        if (inputs == null || inputs.isEmpty()) {
            return new EmbeddingResponse(List.of());
        }
        List<Embedding> embeddings = new ArrayList<>();
        for (int i = 0; i < inputs.size(); i++) {
            float[] vec = embedVector(inputs.get(i));
            embeddings.add(new Embedding(vec, i));
        }
        return new EmbeddingResponse(embeddings);
    }

    @Override
    public float[] embed(Document document) {
        return embedVector(document.getText());
    }

    private float[] embedVector(String text) {
        if (text == null || text.isBlank()) {
            return new float[0];
        }
        String key = text.strip();
        float[] cached = cache.get(key);
        if (cached != null) {
            return copy(cached);
        }
        synchronized (predictLock) {
            float[] again = cache.get(key);
            if (again != null) {
                return copy(again);
            }
            try {
                float[] vec = predictor.predict(key);
                if (vec == null) {
                    return new float[0];
                }
                if (cache.size() >= MAX_CACHE_ENTRIES) {
                    cache.clear();
                }
                cache.put(key, copy(vec));
                return vec;
            } catch (TranslateException e) {
                throw new IllegalStateException("[DJL-EMBED] Fallo al generar embedding", e);
            }
        }
    }

    private static float[] copy(float[] v) {
        float[] c = new float[v.length];
        System.arraycopy(v, 0, c, 0, v.length);
        return c;
    }

    /** Cierra recursos nativos (PyTorch). */
    public void close() {
        synchronized (predictLock) {
            try {
                predictor.close();
            } catch (Exception e) {
                log.warn("[DJL-EMBED] Al cerrar predictor: {}", e.getMessage());
            }
            try {
                model.close();
            } catch (Exception e) {
                log.warn("[DJL-EMBED] Al cerrar modelo: {}", e.getMessage());
            }
            cache.clear();
        }
    }
}

package com.botai.domain.chatbot.model;

/**
 * Fragmento recuperado con distancia coseno pgvector ({@code <=>}).
 * Similitud aproximada: {@code 1 - cosineDistance} (vectores normalizados).
 */
public record KnowledgeChunkHit(KnowledgeChunk chunk, double cosineDistance) {

    public double similarity() {
        return Math.max(0.0, 1.0 - cosineDistance);
    }
}

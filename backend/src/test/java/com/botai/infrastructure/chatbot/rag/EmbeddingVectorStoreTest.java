package com.botai.infrastructure.chatbot.rag;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class EmbeddingVectorStoreTest {

    @Test
    void djlUsesEmbedding384() {
        EmbeddingVectorStore store = new EmbeddingVectorStore("djl", 1536);
        assertEquals("embedding_384", store.columnName());
        assertEquals(384, store.dimensions());
        assertTrue(store.selectPendingEmbeddingsSql().contains("embedding_384 IS NULL"));
    }

    @Test
    void apiUsesEmbedding1536ByDefault() {
        EmbeddingVectorStore store = new EmbeddingVectorStore("api", 1536);
        assertEquals("embedding_1536", store.columnName());
        assertEquals(1536, store.dimensions());
    }

    @Test
    void rejectsUnsupportedApiDimensions() {
        assertThrows(IllegalArgumentException.class, () -> new EmbeddingVectorStore("api", 768));
    }
}

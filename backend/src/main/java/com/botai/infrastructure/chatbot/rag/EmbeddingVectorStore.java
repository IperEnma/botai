package com.botai.infrastructure.chatbot.rag;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Columna pgvector activa según {@code bot.embedding.provider}: DJL → {@code embedding_384},
 * API → {@code embedding_1536} (u otra dimensión soportada vía {@code bot.embedding.api-dimensions}).
 * Permite compartir la misma BD entre local (DJL) y prod (OpenRouter) sin ALTER destruyendo el otro perfil.
 */
@Component
public class EmbeddingVectorStore {

    private final String columnName;
    private final int dimensions;

    public EmbeddingVectorStore(
            @Value("${bot.embedding.provider:djl}") String provider,
            @Value("${bot.embedding.api-dimensions:1536}") int apiDimensions) {
        if ("api".equalsIgnoreCase(provider)) {
            this.dimensions = apiDimensions;
            this.columnName = columnForDimensions(apiDimensions);
        } else {
            this.dimensions = 384;
            this.columnName = "embedding_384";
        }
    }

    public String columnName() {
        return columnName;
    }

    public int dimensions() {
        return dimensions;
    }

    public void requireMatchingSize(int vectorSize) {
        if (vectorSize != dimensions) {
            throw new IllegalArgumentException(
                    "El modelo devolvió " + vectorSize + " dimensiones pero la columna activa "
                            + columnName + " espera " + dimensions
                            + " (revisá BOT_EMBEDDING_PROVIDER y bot.embedding.api-dimensions)");
        }
    }

    public String selectPendingEmbeddingsSql() {
        return "SELECT id, topic, content FROM knowledge_chunk WHERE active = true AND "
                + columnName + " IS NULL";
    }

    public String updateEmbeddingSql() {
        return "UPDATE knowledge_chunk SET " + columnName + " = CAST(? AS vector) WHERE id = ?";
    }

    public String clearEmbeddingSql() {
        return "UPDATE knowledge_chunk SET " + columnName + " = NULL WHERE id = ?";
    }

    public String similaritySqlTenant(boolean filtered) {
        if (filtered) {
            return "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk "
                    + "WHERE active = true AND " + columnName + " IS NOT NULL AND tenant_id = ? "
                    + "AND (" + columnName + " <=> CAST(? AS vector)) <= ? "
                    + "ORDER BY " + columnName + " <=> CAST(? AS vector) LIMIT ?";
        }
        return "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk "
                + "WHERE active = true AND " + columnName + " IS NOT NULL AND tenant_id = ? "
                + "ORDER BY " + columnName + " <=> CAST(? AS vector) LIMIT ?";
    }

    public String similaritySqlGlobal(boolean filtered) {
        if (filtered) {
            return "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk "
                    + "WHERE active = true AND " + columnName + " IS NOT NULL "
                    + "AND (" + columnName + " <=> CAST(? AS vector)) <= ? "
                    + "ORDER BY " + columnName + " <=> CAST(? AS vector) LIMIT ?";
        }
        return "SELECT topic, content, COALESCE(keywords, '') FROM knowledge_chunk "
                + "WHERE active = true AND " + columnName + " IS NOT NULL "
                + "ORDER BY " + columnName + " <=> CAST(? AS vector) LIMIT ?";
    }

    private static String columnForDimensions(int dims) {
        return switch (dims) {
            case 384 -> "embedding_384";
            case 1536 -> "embedding_1536";
            default -> throw new IllegalArgumentException(
                    "Dimensiones no soportadas: " + dims + ". Usá 384 (DJL) o 1536 (OpenAI small). "
                            + "Para otra dimensión hay que añadir columna embedding_<dims>.");
        };
    }
}

package com.botai.infrastructure.chatbot.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Ajustes operativos del bot (umbrales, ventanas, temperaturas).
 * Infraestructura (proveedores, secretos, URLs) sigue en claves hermanas del mismo prefijo {@code bot.*}.
 * No hay flags de modos alternativos: el pipeline es único; solo se tunan números.
 */
@Component
@ConfigurationProperties(prefix = "bot")
public class BotProperties {

    private final Rag rag = new Rag();
    private final Tools tools = new Tools();
    private final Memory memory = new Memory();
    private final Session session = new Session();
    private final Buffer buffer = new Buffer();
    private final Llm llm = new Llm();

    public Rag getRag() { return rag; }
    public Tools getTools() { return tools; }
    public Memory getMemory() { return memory; }
    public Session getSession() { return session; }
    public Buffer getBuffer() { return buffer; }
    public Llm getLlm() { return llm; }

    public static class Rag {
        private int maxChunks = 3;
        private double minSimilarity = 0.0;
        private int historyTurnsForQuery = 2;
        private double cragMinAvgSimilarity = 0.52;
        private double cragMinChunkSimilarity = 0.40;
        private int retrievalPrefetchMultiplier = 2;
        private long embedRetryDelayMs = 600_000L;

        public int getMaxChunks() { return maxChunks; }
        public void setMaxChunks(int maxChunks) { this.maxChunks = maxChunks; }
        public double getMinSimilarity() { return minSimilarity; }
        public void setMinSimilarity(double minSimilarity) { this.minSimilarity = minSimilarity; }
        public int getHistoryTurnsForQuery() { return historyTurnsForQuery; }
        public void setHistoryTurnsForQuery(int historyTurnsForQuery) { this.historyTurnsForQuery = historyTurnsForQuery; }
        public double getCragMinAvgSimilarity() { return cragMinAvgSimilarity; }
        public void setCragMinAvgSimilarity(double cragMinAvgSimilarity) { this.cragMinAvgSimilarity = cragMinAvgSimilarity; }
        public double getCragMinChunkSimilarity() { return cragMinChunkSimilarity; }
        public void setCragMinChunkSimilarity(double cragMinChunkSimilarity) { this.cragMinChunkSimilarity = cragMinChunkSimilarity; }
        public int getRetrievalPrefetchMultiplier() { return retrievalPrefetchMultiplier; }
        public void setRetrievalPrefetchMultiplier(int retrievalPrefetchMultiplier) {
            this.retrievalPrefetchMultiplier = retrievalPrefetchMultiplier;
        }
        public long getEmbedRetryDelayMs() { return embedRetryDelayMs; }
        public void setEmbedRetryDelayMs(long embedRetryDelayMs) { this.embedRetryDelayMs = embedRetryDelayMs; }
    }

    public static class Tools {
        private int maxCallsPerTurn = 4;

        public int getMaxCallsPerTurn() { return maxCallsPerTurn; }
        public void setMaxCallsPerTurn(int maxCallsPerTurn) { this.maxCallsPerTurn = maxCallsPerTurn; }
    }

    public static class Memory {
        private int maxHistoryTurns = 10;

        public int getMaxHistoryTurns() { return maxHistoryTurns; }
        public void setMaxHistoryTurns(int maxHistoryTurns) { this.maxHistoryTurns = maxHistoryTurns; }
    }

    public static class Session {
        private int idleMinutes = 45;

        public int getIdleMinutes() { return idleMinutes; }
        public void setIdleMinutes(int idleMinutes) { this.idleMinutes = idleMinutes; }
    }

    public static class Buffer {
        private long debounceMs = 2_500L;

        public long getDebounceMs() { return debounceMs; }
        public void setDebounceMs(long debounceMs) { this.debounceMs = debounceMs; }
    }

    public static class Llm {
        private final Temperature temperature = new Temperature();

        public Temperature getTemperature() { return temperature; }

        public static class Temperature {
            private double classifier = 0.1;
            private double ragReply = 0.3;
            private double selfReview = 0.0;

            public double getClassifier() { return classifier; }
            public void setClassifier(double classifier) { this.classifier = classifier; }
            public double getRagReply() { return ragReply; }
            public void setRagReply(double ragReply) { this.ragReply = ragReply; }
            public double getSelfReview() { return selfReview; }
            public void setSelfReview(double selfReview) { this.selfReview = selfReview; }
        }
    }
}

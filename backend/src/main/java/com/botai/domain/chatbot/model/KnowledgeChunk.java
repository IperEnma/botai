package com.botai.domain.chatbot.model;

/**
 * Fragmento de conocimiento para RAG (ej. consultorio: horarios, servicios, precios).
 */
public final class KnowledgeChunk {

    private final String topic;
    private final String content;
    private final String keywords;
    private final String sourceType;
    private final String language;

    public KnowledgeChunk(String topic, String content, String keywords) {
        this(topic, content, keywords, null, null);
    }

    public KnowledgeChunk(String topic, String content, String keywords, String sourceType, String language) {
        this.topic = topic != null ? topic : "";
        this.content = content != null ? content : "";
        this.keywords = keywords != null ? keywords : "";
        this.sourceType = sourceType;
        this.language = language;
    }

    public String getTopic() {
        return topic;
    }

    public String getContent() {
        return content;
    }

    public String getKeywords() {
        return keywords;
    }

    public String getSourceType() {
        return sourceType;
    }

    public String getLanguage() {
        return language;
    }
}

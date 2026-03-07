package com.botai.chatbot.domain.model;

/**
 * Fragmento de conocimiento para RAG (ej. consultorio: horarios, servicios, precios).
 */
public final class KnowledgeChunk {

    private final String topic;
    private final String content;
    private final String keywords;

    public KnowledgeChunk(String topic, String content, String keywords) {
        this.topic = topic != null ? topic : "";
        this.content = content != null ? content : "";
        this.keywords = keywords != null ? keywords : "";
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
}

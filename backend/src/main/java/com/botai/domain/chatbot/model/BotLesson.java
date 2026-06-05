package com.botai.domain.chatbot.model;

/**
 * Contexto de negocio activado por palabras clave (jerga, reglas de tono, políticas en chat).
 */
public final class BotLesson {

    private final String name;
    private final String triggerKeywords;
    private final String content;

    public BotLesson(String name, String triggerKeywords, String content) {
        this.name = name != null ? name : "";
        this.triggerKeywords = triggerKeywords != null ? triggerKeywords : "";
        this.content = content != null ? content : "";
    }

    public String getName() {
        return name;
    }

    public String getTriggerKeywords() {
        return triggerKeywords;
    }

    public String getContent() {
        return content;
    }
}

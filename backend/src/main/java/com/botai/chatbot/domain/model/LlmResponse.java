package com.botai.chatbot.domain.model;

/**
 * Agnostic response from a language model.
 */
public final class LlmResponse {

    private final String text;
    private final boolean success;
    private final String errorMessage;

    public LlmResponse(String text, boolean success, String errorMessage) {
        this.text = text != null ? text : "";
        this.success = success;
        this.errorMessage = errorMessage;
    }

    public static LlmResponse ok(String text) {
        return new LlmResponse(text, true, null);
    }

    public static LlmResponse error(String errorMessage) {
        return new LlmResponse("", false, errorMessage);
    }

    public String getText() {
        return text;
    }

    public boolean isSuccess() {
        return success;
    }

    public String getErrorMessage() {
        return errorMessage;
    }
}

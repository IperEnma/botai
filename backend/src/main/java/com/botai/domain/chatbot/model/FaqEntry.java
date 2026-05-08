package com.botai.domain.chatbot.model;

/**
 * Domain representation of an FAQ entry (intent, keywords, response).
 * Persistence layer maps to/from this or uses it directly.
 */
public final class FaqEntry {

    private final String intent;
    private final String keywords;  // comma-separated or regex pattern
    private final String response;
    private final boolean useRegex;

    public FaqEntry(String intent, String keywords, String response, boolean useRegex) {
        this.intent = intent;
        this.keywords = keywords;
        this.response = response;
        this.useRegex = useRegex;
    }

    public String getIntent() {
        return intent;
    }

    public String getKeywords() {
        return keywords;
    }

    public String getResponse() {
        return response;
    }

    public boolean isUseRegex() {
        return useRegex;
    }
}

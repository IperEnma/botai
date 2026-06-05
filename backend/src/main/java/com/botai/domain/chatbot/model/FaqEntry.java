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
    private final FaqResponseMode responseMode;

    public FaqEntry(String intent, String keywords, String response, boolean useRegex) {
        this(intent, keywords, response, useRegex, FaqResponseMode.FIXED);
    }

    public FaqEntry(String intent, String keywords, String response, boolean useRegex,
                    FaqResponseMode responseMode) {
        this.intent = intent;
        this.keywords = keywords;
        this.response = response;
        this.useRegex = useRegex;
        this.responseMode = responseMode != null ? responseMode : FaqResponseMode.FIXED;
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

    public FaqResponseMode getResponseMode() {
        return responseMode;
    }
}

package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.service.HybridAiService;
import org.springframework.stereotype.Component;

/**
 * Validates/sanitizes LLM output. Ensures we don't expose invalid or invented content.
 */
@Component
public class DefaultResponseValidator implements HybridAiService.ResponseValidator {

    private static final int MAX_LENGTH = 1000;

    @Override
    public String validateAndSanitize(String rawResponse) {
        if (rawResponse == null) return "";
        String s = rawResponse.strip();
        if (s.length() > MAX_LENGTH) {
            s = s.substring(0, MAX_LENGTH) + "...";
        }
        return s;
    }
}

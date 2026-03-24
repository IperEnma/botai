package com.botai.chatbot.application.service.conversation.common;

import com.botai.chatbot.domain.model.FaqEntry;
import com.botai.chatbot.domain.repository.FaqRepository;

import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * FAQ matching service. Channel and AI agnostic.
 * Matches by keywords or regex and returns the response.
 */
public class FaqService {

    private final FaqRepository faqRepository;

    public FaqService(FaqRepository faqRepository) {
        this.faqRepository = faqRepository;
    }

    /**
     * Tries to find an FAQ match for the given text. First match wins.
     */
    public Optional<FaqMatch> findMatch(String userText) {
        if (userText == null || userText.isBlank()) {
            return Optional.empty();
        }
        String normalized = userText.strip().toLowerCase();
        List<FaqEntry> entries = faqRepository.findAllActive();

        for (FaqEntry entry : entries) {
            if (entry.isUseRegex()) {
                try {
                    if (Pattern.compile(entry.getKeywords(), Pattern.CASE_INSENSITIVE).matcher(userText).find()) {
                        return Optional.of(new FaqMatch(entry.getIntent(), entry.getResponse()));
                    }
                } catch (PatternSyntaxException ignored) {
                    // invalid regex, skip
                }
            } else {
                String[] keywords = entry.getKeywords().toLowerCase().split("[,;\\s]+");
                for (String kw : keywords) {
                    if (kw.isBlank()) continue;
                    if (normalized.contains(kw.trim())) {
                        return Optional.of(new FaqMatch(entry.getIntent(), entry.getResponse()));
                    }
                }
            }
        }
        return Optional.empty();
    }

    public record FaqMatch(String intent, String response) {}
}

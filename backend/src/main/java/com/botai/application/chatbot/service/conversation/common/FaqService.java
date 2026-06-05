package com.botai.application.chatbot.service.conversation.common;

import com.botai.domain.chatbot.model.FaqEntry;
import com.botai.domain.chatbot.model.FaqResponseMode;
import com.botai.domain.chatbot.repository.FaqRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * FAQ matching service. Channel and AI agnostic.
 * FIXED: respuesta literal; RAG_HINT: inyectar Q+A al contexto generativo.
 */
public class FaqService {

    private static final int MAX_RAG_HINTS = 3;

    private final FaqRepository faqRepository;

    public FaqService(FaqRepository faqRepository) {
        this.faqRepository = faqRepository;
    }

    /**
     * Primera coincidencia con modo FIXED (respuesta directa al usuario).
     */
    public Optional<FaqMatch> findFixedMatch(String userText) {
        return findAllMatches(userText).stream()
            .filter(m -> m.responseMode() == FaqResponseMode.FIXED)
            .findFirst();
    }

    /**
     * Pistas FAQ para enriquecer el contexto RAG (modo RAG_HINT).
     */
    public List<FaqRagHint> findRagHints(String userText) {
        List<FaqRagHint> hints = new ArrayList<>();
        for (FaqMatch match : findAllMatches(userText)) {
            if (match.responseMode() == FaqResponseMode.RAG_HINT) {
                hints.add(new FaqRagHint(match.intent(), match.response()));
                if (hints.size() >= MAX_RAG_HINTS) {
                    break;
                }
            }
        }
        return hints;
    }

    /**
     * @deprecated Usar {@link #findFixedMatch(String)} para respuestas directas.
     */
    @Deprecated
    public Optional<FaqMatch> findMatch(String userText) {
        return findFixedMatch(userText);
    }

    private List<FaqMatch> findAllMatches(String userText) {
        if (userText == null || userText.isBlank()) {
            return List.of();
        }
        String normalized = userText.strip().toLowerCase();
        List<FaqEntry> entries = faqRepository.findAllActive();
        List<FaqMatch> matches = new ArrayList<>();

        for (FaqEntry entry : entries) {
            Optional<FaqMatch> hit = matchEntry(entry, userText, normalized);
            hit.ifPresent(matches::add);
        }
        return matches;
    }

    private Optional<FaqMatch> matchEntry(FaqEntry entry, String userText, String normalized) {
        if (entry.isUseRegex()) {
            try {
                if (Pattern.compile(entry.getKeywords(), Pattern.CASE_INSENSITIVE).matcher(userText).find()) {
                    return Optional.of(toMatch(entry));
                }
            } catch (PatternSyntaxException ignored) {
                // invalid regex, skip
            }
        } else {
            String[] keywords = entry.getKeywords().toLowerCase().split("[,;\\s]+");
            for (String kw : keywords) {
                if (kw.isBlank()) {
                    continue;
                }
                if (normalized.contains(kw.trim())) {
                    return Optional.of(toMatch(entry));
                }
            }
        }
        return Optional.empty();
    }

    private static FaqMatch toMatch(FaqEntry entry) {
        return new FaqMatch(entry.getIntent(), entry.getResponse(), entry.getResponseMode());
    }

    public record FaqMatch(String intent, String response, FaqResponseMode responseMode) {}

    public record FaqRagHint(String intent, String suggestedAnswer) {}
}

package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.BotLesson;
import com.botai.domain.chatbot.repository.BotLessonRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Activa lessons por tenant cuando la consulta coincide con palabras clave configuradas.
 */
public class BotLessonService {

    private final BotLessonRepository botLessonRepository;

    public BotLessonService(BotLessonRepository botLessonRepository) {
        this.botLessonRepository = botLessonRepository;
    }

    public List<BotLesson> findActiveForQuery(String tenantId, String userMessage) {
        if (tenantId == null || tenantId.isBlank() || userMessage == null || userMessage.isBlank()) {
            return List.of();
        }
        String normalized = userMessage.strip().toLowerCase(Locale.ROOT);
        List<BotLesson> active = new ArrayList<>();
        for (BotLesson lesson : botLessonRepository.findAllActiveByTenantId(tenantId)) {
            if (matches(normalized, lesson.getTriggerKeywords())) {
                active.add(lesson);
            }
        }
        return active;
    }

    private static boolean matches(String normalizedQuery, String triggerKeywords) {
        if (triggerKeywords == null || triggerKeywords.isBlank()) {
            return false;
        }
        String[] parts = triggerKeywords.toLowerCase(Locale.ROOT).split("[,;\\s]+");
        for (String part : parts) {
            String kw = part.trim();
            if (kw.length() >= 2 && normalizedQuery.contains(kw)) {
                return true;
            }
        }
        return false;
    }
}

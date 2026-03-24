package com.botai.chatbot.application.orchestration;

import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import org.springframework.stereotype.Component;

/**
 * Decide el {@link ConversationMode} a partir de los flags del tenant (única fuente de verdad para el bifurcado FAQ/IA).
 */
@Component
public class ConversationModeResolver {

    private final FeatureFlagService featureFlagService;

    public ConversationModeResolver(FeatureFlagService featureFlagService) {
        this.featureFlagService = featureFlagService;
    }

    public ConversationMode resolve(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return ConversationMode.NONE;
        }
        boolean faq = featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, tenantId);
        boolean ai = featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
        if (faq && ai) {
            return ConversationMode.FAQ_AND_AI;
        }
        if (faq) {
            return ConversationMode.FAQ_ONLY;
        }
        if (ai) {
            return ConversationMode.AI_ONLY;
        }
        return ConversationMode.NONE;
    }
}

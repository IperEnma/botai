package com.botai.infrastructure.chatbot.config;

import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.infrastructure.chatbot.persistence.jpa.BotJpaRepository;
import com.botai.infrastructure.chatbot.persistence.jpa.FeatureConfigJpaRepository;
import com.botai.infrastructure.chatbot.persistence.entity.BotEntity;
import com.botai.infrastructure.chatbot.persistence.entity.FeatureConfigEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Optional;

/**
 * Feature flags: fuente de verdad es la tabla bot (faq_enabled, ai_enabled, actions_enabled).
 * Así el router respeta lo que el usuario guarda en la web. feature_config se mantiene en sync al actualizar el bot.
 */
@Service
public class FeatureFlagConfigService implements FeatureFlagService {

    private static final Logger log = LoggerFactory.getLogger(FeatureFlagConfigService.class);

    private static final Map<BotFeatures, String> FEATURE_KEYS = Map.of(
        BotFeatures.FAQ_ENABLED, "FAQ_ENABLED",
        BotFeatures.AI_ENABLED, "AI_ENABLED",
        BotFeatures.ACTIONS_ENABLED, "ACTIONS_ENABLED"
    );

    private final BotJpaRepository botRepository;
    private final FeatureConfigJpaRepository featureRepo;

    public FeatureFlagConfigService(BotJpaRepository botRepository, FeatureConfigJpaRepository featureRepo) {
        this.botRepository = botRepository;
        this.featureRepo = featureRepo;
    }

    @Override
    public boolean isEnabled(BotFeatures feature) {
        throw new IllegalStateException("tenantId is required; use isEnabled(feature, tenantId)");
    }

    @Override
    public boolean isEnabled(BotFeatures feature, String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[FEATURE] tenantId ausente o vacío, se considera feature desactivada");
            return false;
        }

        // Fuente de verdad: tabla bot (lo que el usuario guarda en la web)
        Optional<BotEntity> botOpt = botRepository.findByTenantId(tenantId);
        if (botOpt.isPresent()) {
            BotEntity bot = botOpt.get();
            boolean enabled = switch (feature) {
                case FAQ_ENABLED -> bot.isFaqEnabled();
                case AI_ENABLED -> bot.isAiEnabled();
                case ACTIONS_ENABLED -> bot.isActionsEnabled();
            };
            log.debug("[FEATURE] tenant={} {}={} (from bot)", tenantId, FEATURE_KEYS.get(feature), enabled);
            return enabled;
        }

        // Fallback: feature_config (por si hubiera tenant sin bot)
        String key = FEATURE_KEYS.get(feature);
        if (key == null) return false;
        Optional<FeatureConfigEntity> fromDb = featureRepo.findByTenantIdAndFeatureKey(tenantId, key);
        if (fromDb.isPresent()) {
            return fromDb.get().isEnabled();
        }
        return false;
    }
}

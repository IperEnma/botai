package com.botai.chatbot.infrastructure.config;

import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.infrastructure.persistence.jpa.FeatureConfigJpaRepository;
import com.botai.chatbot.infrastructure.persistence.entity.FeatureConfigEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Optional;

/**
 * Feature flags: solo desde la base de datos (por tenant).
 * Si no hay fila para el tenant, la capa está desactivada.
 */
@Service
public class FeatureFlagConfigService implements FeatureFlagService {

    private static final Logger log = LoggerFactory.getLogger(FeatureFlagConfigService.class);

    private static final Map<BotFeatures, String> FEATURE_KEYS = Map.of(
        BotFeatures.FAQ_ENABLED, "FAQ_ENABLED",
        BotFeatures.AI_ENABLED, "AI_ENABLED",
        BotFeatures.ACTIONS_ENABLED, "ACTIONS_ENABLED"
    );

    private final FeatureConfigJpaRepository featureRepo;

    public FeatureFlagConfigService(FeatureConfigJpaRepository featureRepo) {
        this.featureRepo = featureRepo;
    }

    @Override
    public boolean isEnabled(BotFeatures feature) {
        throw new IllegalStateException("tenantId is required; use isEnabled(feature, tenantId)");
    }

    @Override
    public boolean isEnabled(BotFeatures feature, String tenantId) {
        String key = FEATURE_KEYS.get(feature);
        if (key == null) return false;
        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[FEATURE] tenantId ausente o vacío, se considera feature desactivada");
            return false;
        }

        Optional<FeatureConfigEntity> fromDb = featureRepo.findByTenantIdAndFeatureKey(tenantId, key);
        if (fromDb.isPresent()) {
            boolean enabled = fromDb.get().isEnabled();
            if ("AI_ENABLED".equals(key)) {
                log.info("[FEATURE] tenant={} AI_ENABLED={} (from DB)", tenantId, enabled);
            }
            return enabled;
        }

        if ("AI_ENABLED".equals(key)) {
            log.info("[FEATURE] tenant={} AI_ENABLED=false (no row in DB)", tenantId);
        }
        return false;
    }
}

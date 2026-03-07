package com.botai.chatbot.domain.feature;

/**
 * Port for feature flags. Implementation can read from DB, config, or env.
 * Multi-tenant: flags are stored per tenant.
 */
public interface FeatureFlagService {

    boolean isEnabled(BotFeatures feature);

    boolean isEnabled(BotFeatures feature, String tenantId);
}

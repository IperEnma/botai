package com.botai.agenda.domain.feature;

/**
 * Puerto del sistema de feature flags de AGENDA. La implementación resuelve
 * cada flag contra la tabla {@code agenda_tenant_config}.
 */
public interface AgendaFeatureFlagService {

    boolean isEnabled(AgendaFeatures feature, String tenantId);
}

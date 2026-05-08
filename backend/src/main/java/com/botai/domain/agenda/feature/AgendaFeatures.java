package com.botai.domain.agenda.feature;

/**
 * Enum de feature flags del módulo AGENDA. Aislado del enum {@code BotFeatures}
 * del bot para respetar la regla de no acoplar paquetes.
 */
public enum AgendaFeatures {
    AGENDA_ENABLED,
    PUBLIC_SEARCH_ENABLED,
    LOYALTY_ENGINE_ENABLED,
    AUTO_NOTIFICATIONS
}

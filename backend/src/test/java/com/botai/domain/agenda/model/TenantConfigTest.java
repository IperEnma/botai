package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests del modelo de feature flags del tenant.
 *
 * <p>Política fail-closed: {@code defaultsFor} devuelve {@code agendaEnabled=false},
 * de modo que un tenant sin fila en {@code agenda_tenant_config} no activa
 * el módulo por accidente.</p>
 */
class TenantConfigTest {

    @Test
    void defaultsForEsFailClosedParaAgendaEnabled() {
        TenantConfig config = TenantConfig.defaultsFor("tenant-123");

        assertEquals("tenant-123", config.getTenantId());
        assertFalse(config.isAgendaEnabled(),
                "agendaEnabled debe arrancar apagado (fail-closed)");
        assertTrue(config.isPublicSearchEnabled(),
                "publicSearchEnabled arranca encendido por default");
        assertTrue(config.isLoyaltyEngineEnabled(),
                "loyaltyEngineEnabled arranca encendido por default");
        assertTrue(config.isAutoNotifications(),
                "autoNotifications arranca encendido por default");
    }
}

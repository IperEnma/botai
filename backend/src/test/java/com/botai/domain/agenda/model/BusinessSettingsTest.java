package com.botai.domain.agenda.model;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Valida que {@link BusinessSettings#defaults(UUID)} produce la configuración
 * documentada en el PLAN_AGENDA: 4 horas de cancelación, 3 asistencias mínimas
 * para fidelización, ventana de 30 días, alerta de vencimiento a 7 días / 2 créditos,
 * notificaciones automáticas encendidas.
 */
class BusinessSettingsTest {

    @Test
    void defaultsTraeLosValoresDeNegocioEsperados() {
        UUID businessId = UUID.randomUUID();

        BusinessSettings settings = BusinessSettings.defaults(businessId);

        assertEquals(businessId, settings.getBusinessId(), "El businessId debe conservarse tal cual");
        assertEquals(4, settings.getHoursCancellationLimit(),
                "La ventana default de cancelación debe ser 4 horas");
        assertEquals(3, settings.getLoyaltyMinAttendances(),
                "Las asistencias mínimas default para fidelización deben ser 3");
        assertEquals(30, settings.getLoyaltyWindowDays(),
                "La ventana default de fidelización debe ser 30 días");
        assertEquals(7, settings.getExpirationAlertDays(),
                "La alerta default de vencimiento debe ser a 7 días");
        assertEquals(2, settings.getExpirationAlertCredits(),
                "La alerta default de créditos bajos debe activarse con 2 créditos");
        assertTrue(settings.isAutoNotifyEnabled(),
                "Las notificaciones automáticas deben estar encendidas por default");
    }
}

package com.botai.domain.agenda.service;

import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.LoyaltySuggestion;
import com.botai.domain.agenda.model.LoyaltySuggestionEstado;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LoyaltyDomainServiceTest {

    private LoyaltyDomainService service;
    private BusinessSettings settings; // loyaltyMinAttendances = 3 (defaults)

    @BeforeEach
    void setUp() {
        service = new LoyaltyDomainService();
        settings = BusinessSettings.defaults(UUID.randomUUID());
    }

    // ── debeGenerarSugerencia ─────────────────────────────────────────────────

    @Test
    void conAsistenciasIgualesAlUmbral_debeGenerar() {
        assertTrue(service.debeGenerarSugerencia(3, settings));
    }

    @Test
    void conAsistenciasSuperiorAlUmbral_debeGenerar() {
        assertTrue(service.debeGenerarSugerencia(5, settings));
    }

    @Test
    void conAsistenciasBajoElUmbral_noDebeGenerar() {
        assertFalse(service.debeGenerarSugerencia(2, settings));
    }

    @Test
    void conCeroAsistencias_noDebeGenerar() {
        assertFalse(service.debeGenerarSugerencia(0, settings));
    }

    @Test
    void umbralPersonalizado_respetaConfiguracion() {
        BusinessSettings settings5 = new BusinessSettings(
                UUID.randomUUID(), 4, 5, 60, 7, 2, true, true);
        assertFalse(service.debeGenerarSugerencia(4, settings5),
                "Con 4 asistencias y umbral 5 no debe generar");
        assertTrue(service.debeGenerarSugerencia(5, settings5),
                "Con 5 asistencias e umbral 5 debe generar");
    }

    // ── crearSugerencia ───────────────────────────────────────────────────────

    @Test
    void crearSugerencia_estadoPENDING() {
        UUID businessId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        LoyaltySuggestion result = service.crearSugerencia(businessId, userId);

        assertEquals(LoyaltySuggestionEstado.PENDING, result.getEstado());
    }

    @Test
    void crearSugerencia_triggerRuleCorrecto() {
        LoyaltySuggestion result = service.crearSugerencia(UUID.randomUUID(), UUID.randomUUID());

        assertEquals(LoyaltyDomainService.TRIGGER_THRESHOLD, result.getTriggerRule());
    }

    @Test
    void crearSugerencia_idEsNullParaQueElAdapterLoAsigne() {
        LoyaltySuggestion result = service.crearSugerencia(UUID.randomUUID(), UUID.randomUUID());

        assertNull(result.getId(), "El id debe ser null; el adapter asigna UUID en save()");
    }

    @Test
    void crearSugerencia_preservaBusinessIdYUserId() {
        UUID businessId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        LoyaltySuggestion result = service.crearSugerencia(businessId, userId);

        assertEquals(businessId, result.getBusinessId());
        assertEquals(userId, result.getUserId());
    }

    // ── withEstado (transición inmutable) ─────────────────────────────────────

    @Test
    void withEstado_creaInstanciaNueva() {
        LoyaltySuggestion original = service.crearSugerencia(UUID.randomUUID(), UUID.randomUUID());

        LoyaltySuggestion sent = original.withEstado(LoyaltySuggestionEstado.SENT);

        assertEquals(LoyaltySuggestionEstado.PENDING, original.getEstado(),
                "El original no debe mutar");
        assertEquals(LoyaltySuggestionEstado.SENT, sent.getEstado());
    }
}

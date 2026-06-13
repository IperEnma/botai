package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class TenantBusinessSettingsControllerTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-settings";

    private UUID businessId;

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update(
                "DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled, public_search_enabled, loyalty_engine_enabled, auto_notifications, created_at, updated_at) VALUES (?, TRUE, TRUE, TRUE, TRUE, NOW(), NOW())", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo, created_at, updated_at) VALUES (?, ?, 'Negocio Settings', TRUE, NOW(), NOW())",
                businessId, TENANT_ID);
        stubAgendaTenant(TENANT_ID);
    }

    @Test
    void obtenerSettings_sinFilaEnDB_devuelveDefaults() throws Exception {
        mockMvc.perform(get("/api/agenda/me/businesses/{b}/settings", businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.businessId").value(businessId.toString()))
                .andExpect(jsonPath("$.hoursCancellationLimit").value(4))
                .andExpect(jsonPath("$.loyaltyMinAttendances").value(3))
                .andExpect(jsonPath("$.loyaltyWindowDays").value(30))
                .andExpect(jsonPath("$.expirationAlertDays").value(7))
                .andExpect(jsonPath("$.expirationAlertCredits").value(2))
                .andExpect(jsonPath("$.autoNotifyEnabled").value(true));
    }

    @Test
    void obtenerSettings_conFilaEnDB_devuelveValoresGuardados() throws Exception {
        jdbc.update(
                "INSERT INTO agenda_business_settings " +
                "(business_id, hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, " +
                " expiration_alert_days, expiration_alert_credits, auto_notify_enabled, require_booking_confirmation, created_at, updated_at) " +
                "VALUES (?, 8, 10, 90, 3, 1, FALSE, TRUE, NOW(), NOW())",
                businessId);

        mockMvc.perform(get("/api/agenda/me/businesses/{b}/settings", businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hoursCancellationLimit").value(8))
                .andExpect(jsonPath("$.loyaltyMinAttendances").value(10))
                .andExpect(jsonPath("$.loyaltyWindowDays").value(90))
                .andExpect(jsonPath("$.expirationAlertDays").value(3))
                .andExpect(jsonPath("$.expirationAlertCredits").value(1))
                .andExpect(jsonPath("$.autoNotifyEnabled").value(false));
    }

    @Test
    void actualizarSettings_devuelve200YPersiste() throws Exception {
        jdbc.update("INSERT INTO agenda_business_settings (business_id, hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, expiration_alert_days, expiration_alert_credits, auto_notify_enabled, require_booking_confirmation, created_at, updated_at) VALUES (?, 4, 3, 30, 7, 2, TRUE, TRUE, NOW(), NOW())", businessId);

        String body = """
                {
                  "hoursCancellationLimit": 6,
                  "loyaltyMinAttendances": 5,
                  "loyaltyWindowDays": 60,
                  "expirationAlertDays": 14,
                  "expirationAlertCredits": 3,
                  "autoNotifyEnabled": false,
                  "requireBookingConfirmation": true
                }
                """;

        mockMvc.perform(put("/api/agenda/me/businesses/{b}/settings", businessId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hoursCancellationLimit").value(6))
                .andExpect(jsonPath("$.loyaltyMinAttendances").value(5))
                .andExpect(jsonPath("$.loyaltyWindowDays").value(60))
                .andExpect(jsonPath("$.expirationAlertDays").value(14))
                .andExpect(jsonPath("$.expirationAlertCredits").value(3))
                .andExpect(jsonPath("$.autoNotifyEnabled").value(false));

        Integer hours = jdbc.queryForObject(
                "SELECT hours_cancellation_limit FROM agenda_business_settings WHERE business_id = ?",
                Integer.class, businessId);
        assertNotNull(hours);
        assertEquals(6, hours.intValue());
    }

    @Test
    void actualizarSettings_businessInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();
        String body = """
                {
                  "hoursCancellationLimit": 2,
                  "loyaltyMinAttendances": 3,
                  "loyaltyWindowDays": 60,
                  "expirationAlertDays": 7,
                  "expirationAlertCredits": 2,
                  "autoNotifyEnabled": true,
                  "requireBookingConfirmation": false
                }
                """;

        mockMvc.perform(put("/api/agenda/me/businesses/{b}/settings", inexistente)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BUSINESS_NOT_FOUND"));
    }
}

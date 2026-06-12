package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class MeBookingsControllerTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-bookings";
    private static final String USER_ID_HEADER = "X-User-Id";

    private UUID businessId;
    private UUID userId;

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update(
                "DELETE FROM agenda_bookings bk USING agenda_businesses b " +
                "WHERE bk.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update(
                "DELETE FROM agenda_services s USING agenda_businesses b " +
                "WHERE s.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update(
                "DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_users WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled, public_search_enabled, loyalty_engine_enabled, auto_notifications, created_at, updated_at) VALUES (?, TRUE, TRUE, TRUE, TRUE, NOW(), NOW())", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo, created_at, updated_at) VALUES (?, ?, 'Negocio Bookings', TRUE, NOW(), NOW())",
                businessId, TENANT_ID);
        jdbc.update("INSERT INTO agenda_business_settings (business_id, hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, expiration_alert_days, expiration_alert_credits, auto_notify_enabled, require_booking_confirmation, created_at, updated_at) VALUES (?, 4, 3, 30, 7, 2, TRUE, TRUE, NOW(), NOW())", businessId);

        userId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_users (id, tenant_id, nombre, tipo_usuario, activo, created_at, updated_at) VALUES (?, ?, 'Usuario Test', 'CLIENT', TRUE, NOW(), NOW())",
                userId, TENANT_ID);
        stubAgendaTenant(TENANT_ID);
    }

    @Test
    void listarMisReservas_sinReservas_devuelveListaVacia() throws Exception {
        mockMvc.perform(get("/api/agenda/me/businesses/{b}/bookings", businessId)
                        .header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void listarMisReservas_businessInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();
        mockMvc.perform(get("/api/agenda/me/businesses/{b}/bookings", inexistente)
                        .header(USER_ID_HEADER, userId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BUSINESS_NOT_FOUND"));
    }

    @Test
    void listarMisReservas_conBookingsEnDB_devuelveLista() throws Exception {
        UUID serviceId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Corte', 30, TRUE, NOW(), NOW())",
                serviceId, businessId);

        UUID bookingId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_bookings (id, business_id, service_id, user_id, " +
                "fecha_hora_inicio, fecha_hora_fin, estado, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, '2027-01-10 10:00', '2027-01-10 10:30', 'CONFIRMED', NOW(), NOW())",
                bookingId, businessId, serviceId, userId);

        mockMvc.perform(get("/api/agenda/me/businesses/{b}/bookings", businessId)
                        .header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").value(bookingId.toString()))
                .andExpect(jsonPath("$[0].estado").value("CONFIRMED"));
    }

    @Test
    void cancelarReservaInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();
        mockMvc.perform(delete("/api/agenda/me/businesses/{b}/bookings/{id}",
                        businessId, inexistente)
                        .header(USER_ID_HEADER, userId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BOOKING_NOT_FOUND"));
    }

    @Test
    void cancelarReservaCancelada_devuelve409() throws Exception {
        UUID serviceId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Masaje', 60, TRUE, NOW(), NOW())",
                serviceId, businessId);

        UUID bookingId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_bookings (id, business_id, service_id, user_id, " +
                "fecha_hora_inicio, fecha_hora_fin, estado, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, '2027-06-10 14:00', '2027-06-10 15:00', 'CANCELLED', NOW(), NOW())",
                bookingId, businessId, serviceId, userId);

        mockMvc.perform(delete("/api/agenda/me/businesses/{b}/bookings/{id}",
                        businessId, bookingId)
                        .header(USER_ID_HEADER, userId))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("BOOKING_NOT_CANCELLABLE"));
    }
}

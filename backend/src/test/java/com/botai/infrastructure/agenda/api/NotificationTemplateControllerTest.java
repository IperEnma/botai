package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class NotificationTemplateControllerTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-notif-tmpl";
    private static final String BASE_URL =
            "/api/agenda/me/businesses/{b}/notification-templates";

    private UUID businessId;

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update(
                "DELETE FROM agenda_notification_templates WHERE business_id IN " +
                "(SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update(
                "DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled, public_search_enabled, loyalty_engine_enabled, auto_notifications, created_at, updated_at) VALUES (?, TRUE, TRUE, TRUE, TRUE, NOW(), NOW())", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo, created_at, updated_at) VALUES (?, ?, 'Negocio Templates', TRUE, NOW(), NOW())",
                businessId, TENANT_ID);
        jdbc.update("INSERT INTO agenda_business_settings (business_id, hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, expiration_alert_days, expiration_alert_credits, auto_notify_enabled, require_booking_confirmation, created_at, updated_at) VALUES (?, 4, 3, 30, 7, 2, TRUE, TRUE, NOW(), NOW())", businessId);
        stubAgendaTenant(TENANT_ID);
    }

    @Test
    void listar_sinPlantillas_devuelveListaVacia() throws Exception {
        mockMvc.perform(get(BASE_URL, businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void listar_businessInexistente_devuelve404() throws Exception {
        mockMvc.perform(get(BASE_URL, UUID.randomUUID()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BUSINESS_NOT_FOUND"));
    }

    @Test
    void listar_conPlantillasEnDB_devuelveLista() throws Exception {
        jdbc.update(
                "INSERT INTO agenda_notification_templates " +
                "(id, business_id, codigo, canal, titulo, cuerpo, created_at, updated_at) " +
                "VALUES (?, ?, 'EXPIRACION_PRONTO', 'IN_APP', 'Título', 'Cuerpo', NOW(), NOW())",
                UUID.randomUUID(), businessId);

        mockMvc.perform(get(BASE_URL, businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].codigo").value("EXPIRACION_PRONTO"))
                .andExpect(jsonPath("$[0].canal").value("IN_APP"))
                .andExpect(jsonPath("$[0].titulo").value("Título"));
    }

    @Test
    void crear_devuelve201ConIdGenerado() throws Exception {
        String body = """
                {
                  "codigo": "LOYALTY_TRIGGERED",
                  "canal": "IN_APP",
                  "titulo": "¡Volvé pronto!",
                  "cuerpo": "Alcanzaste un hito. Renová tu plan."
                }
                """;

        MvcResult result = mockMvc.perform(post(BASE_URL, businessId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.codigo").value("LOYALTY_TRIGGERED"))
                .andExpect(jsonPath("$.canal").value("IN_APP"))
                .andExpect(jsonPath("$.titulo").value("¡Volvé pronto!"))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        UUID templateId = UUID.fromString(json.get("id").asText());

        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_notification_templates WHERE id = ? AND business_id = ?",
                Integer.class, templateId, businessId);
        assertEquals(1, count);
    }

    @Test
    void crear_sinCamposObligatorios_devuelve400() throws Exception {
        String body = """
                {
                  "canal": "IN_APP",
                  "titulo": "Sin código"
                }
                """;

        mockMvc.perform(post(BASE_URL, businessId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void actualizar_devuelve200ConNuevosDatos() throws Exception {
        UUID templateId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_notification_templates " +
                "(id, business_id, codigo, canal, titulo, cuerpo, created_at, updated_at) " +
                "VALUES (?, ?, 'SALDO_BAJO', 'IN_APP', 'Título original', 'Cuerpo original', NOW(), NOW())",
                templateId, businessId);

        String body = """
                {
                  "codigo": "SALDO_BAJO",
                  "canal": "IN_APP",
                  "titulo": "Título actualizado",
                  "cuerpo": "Cuerpo actualizado"
                }
                """;

        mockMvc.perform(put(BASE_URL + "/{id}", businessId, templateId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(templateId.toString()))
                .andExpect(jsonPath("$.titulo").value("Título actualizado"))
                .andExpect(jsonPath("$.cuerpo").value("Cuerpo actualizado"));
    }

    @Test
    void actualizar_inexistente_devuelve400() throws Exception {
        String body = """
                {
                  "codigo": "SALDO_BAJO",
                  "canal": "IN_APP",
                  "titulo": "X",
                  "cuerpo": "Y"
                }
                """;

        mockMvc.perform(put(BASE_URL + "/{id}", businessId, UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_REQUEST"));
    }

    @Test
    void eliminar_devuelve204YBorraDeDB() throws Exception {
        UUID templateId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_notification_templates " +
                "(id, business_id, codigo, canal, titulo, cuerpo, created_at, updated_at) " +
                "VALUES (?, ?, 'EXPIRACION_PRONTO', 'IN_APP', 'T', 'C', NOW(), NOW())",
                templateId, businessId);

        mockMvc.perform(delete(BASE_URL + "/{id}", businessId, templateId))
                .andExpect(status().isNoContent());

        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_notification_templates WHERE id = ?",
                Integer.class, templateId);
        assertEquals(0, count);
    }

    @Test
    void eliminar_inexistente_devuelve400() throws Exception {
        mockMvc.perform(delete(BASE_URL + "/{id}", businessId, UUID.randomUUID()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_REQUEST"));
    }
}

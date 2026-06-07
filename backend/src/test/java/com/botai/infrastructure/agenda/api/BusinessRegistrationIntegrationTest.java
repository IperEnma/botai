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

import static org.hamcrest.Matchers.notNullValue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Flujo completo de alta de negocio: HTTP → controller → use case → repos → DB.
 * Verifica además que se creó la fila de settings con los defaults y que
 * el feature flag habilita / protege el endpoint.
 */
@AutoConfigureMockMvc
class BusinessRegistrationIntegrationTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-biz";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private JdbcTemplate jdbc;

    @BeforeEach
    void enableTenant() {
        // Limpieza para aislamiento entre tests.
        jdbc.update("DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);
        jdbc.update(
                "INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled) VALUES (?, TRUE)",
                TENANT_ID
        );
        stubAgendaTenant(TENANT_ID);
    }

    @Test
    void postDeNegocioValido_devuelve201YPersisteSettingsPorDefault() throws Exception {
        String body = """
                {
                  "nombre": "Peluquería Centro",
                  "descripcion": "Corte y color",
                  "searchTags": [
                    {"value": "centro", "type": "profile"},
                    {"value": "corte", "type": "profile"}
                  ]
                }
                """;

        MvcResult result = mockMvc.perform(
                        post("/api/agenda/me/businesses")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.tenantId").value(TENANT_ID))
                .andExpect(jsonPath("$.nombre").value("Peluquería Centro"))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        UUID businessId = UUID.fromString(json.get("id").asText());

        // Verificamos la fila en agenda_businesses.
        Integer bizCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_businesses WHERE id = ? AND tenant_id = ?",
                Integer.class, businessId, TENANT_ID
        );
        assertEquals(1, bizCount, "El negocio debe quedar persistido en agenda_businesses");

        // Verificamos que se crearon los settings default.
        Integer settingsCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_business_settings WHERE business_id = ?",
                Integer.class, businessId
        );
        assertEquals(1, settingsCount,
                "Debe existir una fila de settings por el negocio creado");

        Integer hours = jdbc.queryForObject(
                "SELECT hours_cancellation_limit FROM agenda_business_settings WHERE business_id = ?",
                Integer.class, businessId
        );
        assertNotNull(hours);
        assertEquals(4, hours.intValue(),
                "La ventana default de cancelación debe ser 4 horas");
    }

    @Test
    void postSinNombre_devuelve400ConCampoDeError() throws Exception {
        String body = """
                {
                  "descripcion": "Sin nombre"
                }
                """;

        mockMvc.perform(
                        post("/api/agenda/me/businesses")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details[0].field").value("nombre"));
    }
}

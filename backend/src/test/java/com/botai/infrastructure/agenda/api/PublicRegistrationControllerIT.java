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

import static org.hamcrest.Matchers.notNullValue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Tests de integración del endpoint POST /api/agenda/public/register.
 * Requieren Docker (heredan de {@link AbstractAgendaIntegrationTest}).
 */
@AutoConfigureMockMvc
class PublicRegistrationControllerIT extends AbstractAgendaIntegrationTest {

    private static final String URL = "/api/agenda/public/register";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @BeforeEach
    void limpiarDatos() {
        // Limpiar en orden de FK para aislamiento entre tests
        jdbc.update("DELETE FROM agenda_business_category");
        jdbc.update("DELETE FROM agenda_business_settings");
        jdbc.update("DELETE FROM agenda_businesses");
        jdbc.update("DELETE FROM agenda_users");
        jdbc.update("DELETE FROM agenda_tenant_config");
        jdbc.update("DELETE FROM agenda_tenant_accounts");
    }

    @Test
    void postValido_devuelve201ConTenantIdBusinessIdYAccessCode() throws Exception {
        String body = """
                {
                  "nombrePropietario": "Juan Perez",
                  "email": "juan@example.com",
                  "telefono": "+5491112345678",
                  "nombreNegocio": "Peluquería Juan"
                }
                """;

        MvcResult result = mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tenantId", notNullValue()))
                .andExpect(jsonPath("$.businessId", notNullValue()))
                .andExpect(jsonPath("$.accessCode", notNullValue()))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        String tenantId = json.get("tenantId").asText();
        String accessCode = json.get("accessCode").asText();

        assertEquals(8, accessCode.length(), "El accessCode debe tener exactamente 8 caracteres");

        // Verificar persistencia en la BD
        Integer accountCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_tenant_accounts WHERE tenant_id = ?",
                Integer.class, tenantId
        );
        assertEquals(1, accountCount, "Debe existir una cuenta de tenant en agenda_tenant_accounts");

        Integer configCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_tenant_config WHERE tenant_id = ? AND agenda_enabled = TRUE",
                Integer.class, tenantId
        );
        assertEquals(1, configCount, "Debe existir configuración con agenda_enabled=TRUE");
    }

    @Test
    void registroPorNumero_devuelve201YpersisteNumero() throws Exception {
        String body = """
                {
                  "nombrePropietario": "Ana",
                  "numero": "59899123456",
                  "telefono": "+59899123456",
                  "nombreNegocio": "Salón Ana"
                }
                """;

        MvcResult result = mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tenantId", notNullValue()))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        String tenantId = json.get("tenantId").asText();

        String numero = jdbc.queryForObject(
                "SELECT numero FROM agenda_tenant_accounts WHERE tenant_id = ?",
                String.class, tenantId
        );
        assertEquals("59899123456", numero);

        String email = jdbc.queryForObject(
                "SELECT email FROM agenda_tenant_accounts WHERE tenant_id = ?",
                String.class, tenantId
        );
        assertEquals(null, email);
    }

    @Test
    void emailInvalido_devuelve400() throws Exception {
        String body = """
                {
                  "nombrePropietario": "Juan Perez",
                  "email": "no-es-email",
                  "nombreNegocio": "Peluquería Juan"
                }
                """;

        mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void emailDuplicado_devuelve409() throws Exception {
        String body = """
                {
                  "nombrePropietario": "Juan Perez",
                  "email": "duplicado@example.com",
                  "nombreNegocio": "Negocio Uno"
                }
                """;

        // Primer registro: debe ser exitoso
        mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isCreated());

        // Segundo registro con el mismo email: debe devolver 409
        String bodyDuplicado = """
                {
                  "nombrePropietario": "Pedro Lopez",
                  "email": "duplicado@example.com",
                  "nombreNegocio": "Negocio Dos"
                }
                """;

        mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(bodyDuplicado))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_REGISTERED"));
    }

    @Test
    void nombreNegocioVacio_devuelve400() throws Exception {
        String body = """
                {
                  "nombrePropietario": "Juan Perez",
                  "email": "juan2@example.com",
                  "nombreNegocio": ""
                }
                """;

        mockMvc.perform(
                        post(URL)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }
}

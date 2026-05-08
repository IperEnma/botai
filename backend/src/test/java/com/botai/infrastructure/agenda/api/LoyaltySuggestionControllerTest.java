package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_CLASS)
class LoyaltySuggestionControllerTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-loyalty";

    private UUID businessId;

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update(
                "DELETE FROM agenda_loyalty_suggestions WHERE business_id IN " +
                "(SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update(
                "DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled) VALUES (?, TRUE)", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo) VALUES (?, ?, 'Negocio Loyalty', TRUE)",
                businessId, TENANT_ID);
        jdbc.update("INSERT INTO agenda_business_settings (business_id) VALUES (?)", businessId);
    }

    @Test
    void listarSugerencias_sinRegistros_devuelveListaVacia() throws Exception {
        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions",
                        TENANT_ID, businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void listarSugerencias_businessInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();
        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions",
                        TENANT_ID, inexistente))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BUSINESS_NOT_FOUND"));
    }

    @Test
    void listarSugerencias_conRegistros_devuelveLista() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID suggestionId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_loyalty_suggestions (id, business_id, user_id, trigger_rule, estado) " +
                "VALUES (?, ?, ?, 'LOYALTY_THRESHOLD_REACHED', 'PENDING')",
                suggestionId, businessId, userId);

        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions",
                        TENANT_ID, businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").value(suggestionId.toString()))
                .andExpect(jsonPath("$[0].estado").value("PENDING"));
    }

    @Test
    void listarSugerencias_filtroEstado_devuelveSoloFiltradas() throws Exception {
        UUID userId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_loyalty_suggestions (id, business_id, user_id, trigger_rule, estado) " +
                "VALUES (?, ?, ?, 'LOYALTY_THRESHOLD_REACHED', 'PENDING')",
                UUID.randomUUID(), businessId, userId);
        jdbc.update(
                "INSERT INTO agenda_loyalty_suggestions (id, business_id, user_id, trigger_rule, estado) " +
                "VALUES (?, ?, ?, 'LOYALTY_THRESHOLD_REACHED', 'SENT')",
                UUID.randomUUID(), businessId, userId);

        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions",
                        TENANT_ID, businessId)
                        .param("estado", "PENDING"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].estado").value("PENDING"));
    }

    @Test
    void actualizarEstadoSugerencia_devuelve200ConEstadoActualizado() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID suggestionId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_loyalty_suggestions (id, business_id, user_id, trigger_rule, estado) " +
                "VALUES (?, ?, ?, 'LOYALTY_THRESHOLD_REACHED', 'PENDING')",
                suggestionId, businessId, userId);

        String body = """
                {"estado": "SENT"}
                """;

        mockMvc.perform(patch("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions/{s}",
                        TENANT_ID, businessId, suggestionId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(suggestionId.toString()))
                .andExpect(jsonPath("$.estado").value("SENT"));
    }

    @Test
    void actualizarEstadoSugerencia_inexistente_devuelve400() throws Exception {
        UUID inexistente = UUID.randomUUID();
        String body = """
                {"estado": "DISMISSED"}
                """;

        mockMvc.perform(patch("/api/agenda/tenants/{t}/businesses/{b}/loyalty/suggestions/{s}",
                        TENANT_ID, businessId, inexistente)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_REQUEST"));
    }
}

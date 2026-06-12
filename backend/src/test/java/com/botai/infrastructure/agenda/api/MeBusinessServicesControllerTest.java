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
class MeBusinessServicesControllerTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-svc";

    private UUID businessId;

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update(
                "DELETE FROM agenda_services s USING agenda_businesses b " +
                "WHERE s.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update(
                "DELETE FROM agenda_business_settings bs USING agenda_businesses b " +
                "WHERE bs.business_id = b.id AND b.tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled, public_search_enabled, loyalty_engine_enabled, auto_notifications, created_at, updated_at) VALUES (?, TRUE, TRUE, TRUE, TRUE, NOW(), NOW())", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo, created_at, updated_at) VALUES (?, ?, 'Negocio Test', TRUE, NOW(), NOW())",
                businessId, TENANT_ID);
        jdbc.update("INSERT INTO agenda_business_settings (business_id, hours_cancellation_limit, loyalty_min_attendances, loyalty_window_days, expiration_alert_days, expiration_alert_credits, auto_notify_enabled, require_booking_confirmation, created_at, updated_at) VALUES (?, 4, 3, 30, 7, 2, TRUE, TRUE, NOW(), NOW())", businessId);
        stubAgendaTenant(TENANT_ID);
    }

    @Test
    void crearServicio_devuelve201YPersiste() throws Exception {
        String body = """
                {
                  "nombre": "Corte de cabello",
                  "descripcion": "Corte clásico",
                  "duracionMin": 45,
                  "precio": 1500.00
                }
                """;

        MvcResult result = mockMvc.perform(
                        post("/api/agenda/me/businesses/{b}/services", businessId)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.nombre").value("Corte de cabello"))
                .andExpect(jsonPath("$.duracionMin").value(45))
                .andExpect(jsonPath("$.precio").value(1500.00))
                .andExpect(jsonPath("$.activo").value(true))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        UUID serviceId = UUID.fromString(json.get("id").asText());

        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_services WHERE id = ? AND business_id = ?",
                Integer.class, serviceId, businessId);
        assertEquals(1, count);
    }

    @Test
    void crearServicioSinNombre_devuelve400ConValidationError() throws Exception {
        String body = """
                {
                  "descripcion": "Sin nombre",
                  "duracionMin": 30
                }
                """;

        mockMvc.perform(
                        post("/api/agenda/me/businesses/{b}/services", businessId)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details[0].field").value("nombre"));
    }

    @Test
    void listarServicios_devuelveTodosLosDeLaListaSinFiltro() throws Exception {
        UUID svcId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) " +
                "VALUES (?, ?, 'Manicura', 30, TRUE, NOW(), NOW())",
                svcId, businessId);

        mockMvc.perform(get("/api/agenda/me/businesses/{b}/services", businessId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").value(svcId.toString()))
                .andExpect(jsonPath("$[0].nombre").value("Manicura"));
    }

    @Test
    void listarServiciosSoloActivos_excluye_inactivos() throws Exception {
        UUID activoId = UUID.randomUUID();
        UUID inactivoId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Activo', 20, TRUE, NOW(), NOW())",
                activoId, businessId);
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Inactivo', 20, FALSE, NOW(), NOW())",
                inactivoId, businessId);

        mockMvc.perform(get("/api/agenda/me/businesses/{b}/services", businessId)
                        .param("soloActivos", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nombre").value("Activo"));
    }

    @Test
    void actualizarServicio_devuelve200ConNuevosDatos() throws Exception {
        UUID svcId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Original', 20, TRUE, NOW(), NOW())",
                svcId, businessId);

        String body = """
                {
                  "nombre": "Actualizado",
                  "descripcion": "Nueva descripción",
                  "duracionMin": 60,
                  "precio": 2000.00,
                  "activo": false
                }
                """;

        mockMvc.perform(put("/api/agenda/me/businesses/{b}/services/{s}",
                        businessId, svcId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(svcId.toString()))
                .andExpect(jsonPath("$.nombre").value("Actualizado"))
                .andExpect(jsonPath("$.duracionMin").value(60))
                .andExpect(jsonPath("$.activo").value(false));
    }

    @Test
    void actualizarServicioInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();
        String body = """
                {"nombre":"X","duracionMin":30,"activo":true}
                """;

        mockMvc.perform(put("/api/agenda/me/businesses/{b}/services/{s}",
                        businessId, inexistente)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SERVICE_NOT_FOUND"));
    }

    @Test
    void eliminarServicio_devuelve204YMarcaSoftDelete() throws Exception {
        UUID svcId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo, created_at, updated_at) VALUES (?, ?, 'Para borrar', 30, TRUE, NOW(), NOW())",
                svcId, businessId);

        mockMvc.perform(delete("/api/agenda/me/businesses/{b}/services/{s}",
                        businessId, svcId))
                .andExpect(status().isNoContent());

        Integer softDeleted = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_services WHERE id = ? AND deleted_at IS NOT NULL",
                Integer.class, svcId);
        assertEquals(1, softDeleted);
    }

    @Test
    void eliminarServicioInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();

        mockMvc.perform(delete("/api/agenda/me/businesses/{b}/services/{s}",
                        businessId, inexistente))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SERVICE_NOT_FOUND"));
    }
}

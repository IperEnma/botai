package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.annotation.DirtiesContext;
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
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_CLASS)
class TenantServicesControllerTest extends AbstractAgendaIntegrationTest {

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

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled) VALUES (?, TRUE)", TENANT_ID);

        businessId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre, activo) VALUES (?, ?, 'Negocio Test', TRUE)",
                businessId, TENANT_ID);
        jdbc.update("INSERT INTO agenda_business_settings (business_id) VALUES (?)", businessId);
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
                        post("/api/agenda/tenants/{t}/businesses/{b}/services", TENANT_ID, businessId)
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
                        post("/api/agenda/tenants/{t}/businesses/{b}/services", TENANT_ID, businessId)
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
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo) " +
                "VALUES (?, ?, 'Manicura', 30, TRUE)",
                svcId, businessId);

        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/services", TENANT_ID, businessId))
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
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo) VALUES (?, ?, 'Activo', 20, TRUE)",
                activoId, businessId);
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo) VALUES (?, ?, 'Inactivo', 20, FALSE)",
                inactivoId, businessId);

        mockMvc.perform(get("/api/agenda/tenants/{t}/businesses/{b}/services", TENANT_ID, businessId)
                        .param("soloActivos", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nombre").value("Activo"));
    }

    @Test
    void actualizarServicio_devuelve200ConNuevosDatos() throws Exception {
        UUID svcId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo) VALUES (?, ?, 'Original', 20, TRUE)",
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

        mockMvc.perform(put("/api/agenda/tenants/{t}/businesses/{b}/services/{s}",
                        TENANT_ID, businessId, svcId)
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

        mockMvc.perform(put("/api/agenda/tenants/{t}/businesses/{b}/services/{s}",
                        TENANT_ID, businessId, inexistente)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SERVICE_NOT_FOUND"));
    }

    @Test
    void eliminarServicio_devuelve204YMarcaSoftDelete() throws Exception {
        UUID svcId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min, activo) VALUES (?, ?, 'Para borrar', 30, TRUE)",
                svcId, businessId);

        mockMvc.perform(delete("/api/agenda/tenants/{t}/businesses/{b}/services/{s}",
                        TENANT_ID, businessId, svcId))
                .andExpect(status().isNoContent());

        Integer softDeleted = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_services WHERE id = ? AND deleted_at IS NOT NULL",
                Integer.class, svcId);
        assertEquals(1, softDeleted);
    }

    @Test
    void eliminarServicioInexistente_devuelve404() throws Exception {
        UUID inexistente = UUID.randomUUID();

        mockMvc.perform(delete("/api/agenda/tenants/{t}/businesses/{b}/services/{s}",
                        TENANT_ID, businessId, inexistente))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SERVICE_NOT_FOUND"));
    }
}

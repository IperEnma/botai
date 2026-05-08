package com.botai.infrastructure.agenda.api;

import com.botai.AbstractAgendaIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_CLASS)
class MeNotificationsControllerTest extends AbstractAgendaIntegrationTest {

    private static final String USER_ID_HEADER = "X-User-Id";
    private static final String BASE_URL = "/api/agenda/me/notifications";

    private UUID businessId;
    private UUID userId;

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        businessId = UUID.randomUUID();

        jdbc.update("DELETE FROM agenda_notifications WHERE user_id = ?", userId);
    }

    @Test
    void listar_sinNotificaciones_devuelveListaVacia() throws Exception {
        mockMvc.perform(get(BASE_URL).header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void listar_conNotificaciones_devuelveTodas() throws Exception {
        insertNotification(UUID.randomUUID(), "PENDING");
        insertNotification(UUID.randomUUID(), "SENT");

        mockMvc.perform(get(BASE_URL).header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void listar_filtroEstadoPending_devuelveSoloPending() throws Exception {
        insertNotification(UUID.randomUUID(), "PENDING");
        insertNotification(UUID.randomUUID(), "SENT");

        mockMvc.perform(get(BASE_URL)
                        .header(USER_ID_HEADER, userId)
                        .param("estado", "PENDING"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].estado").value("PENDING"));
    }

    @Test
    void listar_notificacionesDeOtroUsuario_noAparecen() throws Exception {
        UUID otroUsuario = UUID.randomUUID();
        insertNotificationForUser(UUID.randomUUID(), otroUsuario, "PENDING");

        mockMvc.perform(get(BASE_URL).header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void listar_devuelveCamposEsperados() throws Exception {
        UUID notifId = UUID.randomUUID();
        jdbc.update(
                "INSERT INTO agenda_notifications (id, business_id, user_id, canal, titulo, cuerpo, estado) " +
                "VALUES (?, ?, ?, 'IN_APP', 'Título test', 'Cuerpo test', 'PENDING')",
                notifId, businessId, userId);

        mockMvc.perform(get(BASE_URL).header(USER_ID_HEADER, userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(notifId.toString()))
                .andExpect(jsonPath("$[0].titulo").value("Título test"))
                .andExpect(jsonPath("$[0].cuerpo").value("Cuerpo test"))
                .andExpect(jsonPath("$[0].canal").value("IN_APP"))
                .andExpect(jsonPath("$[0].estado").value("PENDING"));
    }

    private void insertNotification(UUID id, String estado) {
        insertNotificationForUser(id, userId, estado);
    }

    private void insertNotificationForUser(UUID id, UUID targetUserId, String estado) {
        jdbc.update(
                "INSERT INTO agenda_notifications (id, business_id, user_id, canal, titulo, cuerpo, estado) " +
                "VALUES (?, ?, ?, 'IN_APP', 'Notif', 'Contenido', ?)",
                id, businessId, targetUserId, estado);
    }
}

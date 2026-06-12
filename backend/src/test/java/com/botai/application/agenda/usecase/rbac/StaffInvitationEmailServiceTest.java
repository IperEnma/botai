package com.botai.application.agenda.usecase.rbac;

import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.notification.AgendaMailer;
import com.botai.infrastructure.config.AppUrlProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class StaffInvitationEmailServiceTest {

    private AgendaMailer mailer;
    private StaffInvitationEmailService service;

    @BeforeEach
    void setUp() {
        mailer = mock(AgendaMailer.class);
        AppUrlProperties urls = new AppUrlProperties();
        urls.setFrontend("http://localhost:5173/");
        service = new StaffInvitationEmailService(mailer, urls, "/login");
    }

    @Test
    void staffInvite_usaTemplateConNombreEquipoRolYLogin() {
        service.sendForInvitation("Pedro", "pedro@example.com",
                Role.STAFF_OPERATOR, List.of("Estudio Norte"));

        ArgumentCaptor<AgendaMailer.MailMessage> captor =
                ArgumentCaptor.forClass(AgendaMailer.MailMessage.class);
        verify(mailer).send(captor.capture());
        AgendaMailer.MailMessage sent = captor.getValue();

        assertEquals("pedro@example.com", sent.to());
        assertEquals("Te agregaron al equipo de Estudio Norte", sent.subject());
        assertTrue(sent.htmlBody().contains("Pedro"));
        assertTrue(sent.htmlBody().contains("Estudio Norte"));
        assertTrue(sent.htmlBody().contains("Profesional"));
        assertTrue(sent.htmlBody().contains("http://localhost:5173/login"));
    }

    @Test
    void receptionInvite_muestraEtiquetaRecepcion() {
        service.sendForInvitation("Ana", "ana@example.com",
                Role.RECEPTION, List.of("Estudio Norte", "Salón Centro"));

        ArgumentCaptor<AgendaMailer.MailMessage> captor =
                ArgumentCaptor.forClass(AgendaMailer.MailMessage.class);
        verify(mailer).send(captor.capture());
        AgendaMailer.MailMessage sent = captor.getValue();

        assertEquals("Te agregaron al equipo de Estudio Norte, Salón Centro", sent.subject());
        assertTrue(sent.htmlBody().contains("Recepción"));
    }

    @Test
    void tenantAdmin_usaTemplateDeBienvenida() {
        service.sendForInvitation("Laura", "laura@example.com",
                Role.TENANT_ADMIN, List.of());

        ArgumentCaptor<AgendaMailer.MailMessage> captor =
                ArgumentCaptor.forClass(AgendaMailer.MailMessage.class);
        verify(mailer).send(captor.capture());
        AgendaMailer.MailMessage sent = captor.getValue();

        assertEquals("Bienvenido a Botai Agenda", sent.subject());
        assertTrue(sent.htmlBody().contains("Laura"));
        assertTrue(sent.htmlBody().contains("Administrador"));
        assertTrue(sent.htmlBody().contains("http://localhost:5173/login"));
    }

    @Test
    void mailerFallido_noPropaga() {
        doThrow(new RuntimeException("smtp down")).when(mailer).send(any());

        assertDoesNotThrow(() -> service.sendForInvitation(
                "Pedro", "pedro@example.com", Role.STAFF_OPERATOR, List.of("Estudio Norte")));
    }
}

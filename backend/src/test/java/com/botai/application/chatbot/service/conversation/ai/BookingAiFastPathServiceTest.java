package com.botai.application.chatbot.service.conversation.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.infrastructure.chatbot.ai.AgendarTools;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import com.botai.infrastructure.agenda.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.agenda.support.AgendaPrimaryBusinessResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BookingAiFastPathServiceTest {

    @Mock
    private AgendarTools agendarTools;
    @Mock
    private MessageHistoryService messageHistoryService;
    @Mock
    private ServiceJpaRepository agendaServiceRepository;
    @Mock
    private AgendaPrimaryBusinessResolver primaryBusinessResolver;

    private BookingAiFastPathService service;

    @BeforeEach
    void setUp() {
        service = new BookingAiFastPathService(agendarTools, messageHistoryService, agendaServiceRepository, primaryBusinessResolver);
    }

    @Test
    void tryExecute_whenAllFieldsPresent_callsAgendarCita() {
        String tenant = "t1";
        UUID bid = UUID.randomUUID();
        when(primaryBusinessResolver.findPrimaryBusinessId(tenant)).thenReturn(Optional.of(bid));
        ServiceEntity s = new ServiceEntity();
        s.setNombre("Corte cabellos");
        s.setActivo(true);
        when(agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(bid)).thenReturn(List.of(s));

        String fecha = LocalDate.now().plusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
        when(messageHistoryService.getHistory("c1", "sess")).thenReturn(List.of(
            "user: Hola quiero Corte cabellos",
            "user: me llamo Juan Pérez García",
            "user: cédula 12345678",
            "user: " + fecha + " a las 10:30"
        ));

        when(agendarTools.verificarCitaExistentePorDocumento(eq("Juan Pérez García"), eq("12345678")))
            .thenReturn(BotPrompts.ToolsAgendar.MSG_SIN_CITA_PREVIA);
        when(agendarTools.agendarCita(
            eq("Corte cabellos"),
            eq(fecha),
            eq("10:30"),
            eq("Juan Pérez García"),
            eq("12345678")))
            .thenReturn(BotPrompts.ToolsAgendar.citaAgendadaOk("Corte cabellos", fecha, "10:30", "Juan Pérez García"));

        Optional<String> out = service.tryExecute(tenant, "c1", "sess", "confirmo");

        assertThat(out).isPresent();
        assertThat(out.get()).contains("Cita agendada correctamente");
        verify(agendarTools).verificarCitaExistentePorDocumento(eq("Juan Pérez García"), eq("12345678"));
        verify(agendarTools).agendarCita(
            eq("Corte cabellos"), eq(fecha), eq("10:30"), eq("Juan Pérez García"), eq("12345678"));
    }

    @Test
    void tryExecute_whenServiceUnknown_returnsEmpty() {
        when(primaryBusinessResolver.findPrimaryBusinessId("t1")).thenReturn(Optional.empty());
        Optional<String> out = service.tryExecute("t1", "c1", "sess", "manicura mañana");
        assertThat(out).isEmpty();
        verify(agendarTools, never()).agendarCita(anyString(), anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void tryExecute_whenExistingAppointment_prependsVerification() {
        String tenant = "t1";
        UUID bid = UUID.randomUUID();
        when(primaryBusinessResolver.findPrimaryBusinessId(tenant)).thenReturn(Optional.of(bid));
        ServiceEntity s = new ServiceEntity();
        s.setNombre("Limpieza bucal");
        s.setActivo(true);
        when(agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(bid)).thenReturn(List.of(s));
        String fecha = LocalDate.now().plusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
        when(messageHistoryService.getHistory("c1", "sess")).thenReturn(List.of(
            "user: 62995895",
            "user: me llamo Enma Alejandro López",
            "user: Limpieza bucal",
            "user: Mañana a las 15"
        ));
        String dup = BotPrompts.ToolsAgendar.citaDuplicadaVerificacion(fecha, "10:00", "Otro servicio");
        when(agendarTools.verificarCitaExistentePorDocumento(eq("Enma Alejandro López"), eq("62995895")))
            .thenReturn(dup);
        when(agendarTools.agendarCita(
            eq("Limpieza bucal"),
            eq(fecha),
            eq("15:00"),
            eq("Enma Alejandro López"),
            eq("62995895")))
            .thenReturn(BotPrompts.ToolsAgendar.citaAgendadaOk("Limpieza bucal", fecha, "15:00", "Enma Alejandro López"));

        Optional<String> out = service.tryExecute(tenant, "c1", "sess", "Sí");

        assertThat(out).isPresent();
        assertThat(out.get()).contains("CITA_EXISTENTE");
        assertThat(out.get()).contains("Cita agendada correctamente");
        verify(agendarTools).verificarCitaExistentePorDocumento(eq("Enma Alejandro López"), eq("62995895"));
    }

    @Test
    void mergeVerifyAndBook_skipsVerifyWhenNoPriorAppointment() {
        String book = BotPrompts.ToolsAgendar.citaAgendadaOk("X", "2026-05-10", "09:00", "N");
        String merged = BookingAiFastPathService.mergeVerifyAndBook(BotPrompts.ToolsAgendar.MSG_SIN_CITA_PREVIA, book);
        assertThat(merged).isEqualTo(book);
    }

    @Test
    void tryExecute_whenNameMissing_returnsEmpty() {
        UUID bid = UUID.randomUUID();
        when(primaryBusinessResolver.findPrimaryBusinessId("t1")).thenReturn(Optional.of(bid));
        ServiceEntity s = new ServiceEntity();
        s.setNombre("Corte");
        s.setActivo(true);
        when(agendaServiceRepository.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(bid)).thenReturn(List.of(s));
        String fecha = LocalDate.now().plusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
        when(messageHistoryService.getHistory("c1", "sess")).thenReturn(List.of(
            "user: Corte " + fecha + " 09:00 doc 12345678"
        ));

        Optional<String> out = service.tryExecute("t1", "c1", "sess", "");
        assertThat(out).isEmpty();
        verify(agendarTools, never()).agendarCita(
            ArgumentMatchers.any(), ArgumentMatchers.any(), ArgumentMatchers.any(), ArgumentMatchers.any(), ArgumentMatchers.any());
    }
}

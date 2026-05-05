package com.botai.agenda.application.usecase.loyalty;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import com.botai.agenda.domain.model.NotificationCanal;
import com.botai.agenda.domain.model.NotificationTemplate;
import com.botai.agenda.domain.notification.NotificationPort;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.LoyaltySuggestionRepository;
import com.botai.agenda.domain.repository.NotificationTemplateRepository;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SendLoyaltySuggestionUseCaseTest {

    private BusinessRepository businessRepository;
    private LoyaltySuggestionRepository suggestionRepository;
    private NotificationTemplateRepository templateRepository;
    private NotificationPort notificationPort;

    private SendLoyaltySuggestionUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID USER_ID = UUID.randomUUID();
    private final UUID SUGGESTION_ID = UUID.randomUUID();
    private final LocalDateTime NOW = LocalDateTime.of(2026, 4, 21, 10, 0);

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        suggestionRepository = mock(LoyaltySuggestionRepository.class);
        templateRepository = mock(NotificationTemplateRepository.class);
        notificationPort = mock(NotificationPort.class);

        useCase = new SendLoyaltySuggestionUseCase(
                businessRepository, suggestionRepository, templateRepository, notificationPort,
                new io.micrometer.core.instrument.simple.SimpleMeterRegistry());

        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        when(suggestionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void enviarConMensajePorDefecto_cuandoNoHayPlantilla() {
        LoyaltySuggestion pending = suggestion(LoyaltySuggestionEstado.PENDING);
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.of(pending));
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(
                BUSINESS_ID, NotificationTemplate.CODIGO_LOYALTY, NotificationCanal.IN_APP))
                .thenReturn(Optional.empty());

        LoyaltySuggestion result = useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID);

        ArgumentCaptor<String> tituloCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> cuerpoCaptor = ArgumentCaptor.forClass(String.class);
        verify(notificationPort).send(
                any(), any(), tituloCaptor.capture(), cuerpoCaptor.capture(), any());

        assertEquals("¡Te echamos de menos!", tituloCaptor.getValue());
        assertEquals(LoyaltySuggestionEstado.SENT, result.getEstado());
    }

    @Test
    void enviarConPlantillaPersonalizada_cuandoExisteTemplate() {
        LoyaltySuggestion pending = suggestion(LoyaltySuggestionEstado.PENDING);
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.of(pending));

        NotificationTemplate template = new NotificationTemplate(
                UUID.randomUUID(), BUSINESS_ID, NotificationTemplate.CODIGO_LOYALTY,
                NotificationCanal.IN_APP, "Título custom", "Cuerpo custom", NOW, NOW);
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(
                BUSINESS_ID, NotificationTemplate.CODIGO_LOYALTY, NotificationCanal.IN_APP))
                .thenReturn(Optional.of(template));

        LoyaltySuggestion result = useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID);

        ArgumentCaptor<String> tituloCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> cuerpoCaptor = ArgumentCaptor.forClass(String.class);
        verify(notificationPort).send(
                any(), any(), tituloCaptor.capture(), cuerpoCaptor.capture(), any());

        assertEquals("Título custom", tituloCaptor.getValue());
        assertEquals("Cuerpo custom", cuerpoCaptor.getValue());
        assertEquals(LoyaltySuggestionEstado.SENT, result.getEstado());
    }

    @Test
    void envio_usaBusinessIdYUserId_correctos() {
        LoyaltySuggestion pending = suggestion(LoyaltySuggestionEstado.PENDING);
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.of(pending));
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(any(), any(), any()))
                .thenReturn(Optional.empty());

        useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID);

        verify(notificationPort).send(
                org.mockito.Mockito.eq(BUSINESS_ID),
                org.mockito.Mockito.eq(USER_ID),
                any(), any(),
                org.mockito.Mockito.eq(NotificationCanal.IN_APP));
    }

    @Test
    void businessNoExiste_lanzaBusinessNotFoundException() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID));

        verify(suggestionRepository, never()).findById(any());
    }

    @Test
    void sugerenciaNoExiste_lanzaIllegalArgumentException() {
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID));

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    @Test
    void sugerenciaPerteneceAOtroNegocio_lanzaIllegalArgumentException() {
        LoyaltySuggestion sugerenciaOtroNegocio = new LoyaltySuggestion(
                SUGGESTION_ID, UUID.randomUUID(), USER_ID, "LOYALTY_THRESHOLD_REACHED",
                LoyaltySuggestionEstado.PENDING, NOW, NOW);
        when(suggestionRepository.findById(SUGGESTION_ID))
                .thenReturn(Optional.of(sugerenciaOtroNegocio));

        assertThrows(IllegalArgumentException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID));
    }

    @Test
    void sugerenciaYaEnviada_lanzaIllegalStateException() {
        LoyaltySuggestion sent = suggestion(LoyaltySuggestionEstado.SENT);
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.of(sent));

        assertThrows(IllegalStateException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID));

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    @Test
    void sugerenciaDescartada_lanzaIllegalStateException() {
        LoyaltySuggestion dismissed = suggestion(LoyaltySuggestionEstado.DISMISSED);
        when(suggestionRepository.findById(SUGGESTION_ID)).thenReturn(Optional.of(dismissed));

        assertThrows(IllegalStateException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SUGGESTION_ID));

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    private LoyaltySuggestion suggestion(LoyaltySuggestionEstado estado) {
        return new LoyaltySuggestion(
                SUGGESTION_ID, BUSINESS_ID, USER_ID, "LOYALTY_THRESHOLD_REACHED",
                estado, NOW, NOW);
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }
}

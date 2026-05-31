package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.dto.IntentClassification;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.LlmRequest;
import com.botai.domain.chatbot.model.LlmResponse;
import com.botai.domain.chatbot.service.LanguageModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class IntentClassifierServiceTest {

    @Mock
    private FeatureFlagService featureFlagService;
    @Mock
    private LanguageModel languageModel;

    private IntentClassifierService service;

    @BeforeEach
    void setUp() {
        when(featureFlagService.isEnabled(eq(BotFeatures.AI_ENABLED), anyString())).thenReturn(true);
        service = new IntentClassifierService(List.of(), Optional.of(languageModel), featureFlagService);
    }

    @Test
    void classify_miniLlm_legacyBookAppointment_normalizedToPublicUrl() {
        when(languageModel.generate(any(LlmRequest.class))).thenReturn(LlmResponse.ok("ACCION_CRM book_appointment"));
        ConversationState noIntent = ConversationState.builder().build();
        IntentClassification r = service.classify("Necesito un turno la próxima semana", "1", noIntent);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("get_agenda_public_url");
        verify(languageModel).generate(any(LlmRequest.class));
    }

    @Test
    void classify_miniLlm_returnsGetAgendaPublicUrl() {
        when(languageModel.generate(any(LlmRequest.class))).thenReturn(LlmResponse.ok("ACCION_CRM get_agenda_public_url"));
        IntentClassification r = service.classify("Necesito un turno la próxima semana", "1", null);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("get_agenda_public_url");
        verify(languageModel).generate(any(LlmRequest.class));
    }

    @Test
    void classify_heuristic_quieroAgendarCiga_skipsLlm() {
        IntentClassification r = service.classify("Quiero agendar una ciga", "tenant-1", null);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("get_agenda_public_url");
        verifyNoInteractions(languageModel);
    }

    @Test
    void classify_heuristic_misTurnos_skipsLlm() {
        IntentClassification r = service.classify("Quiero ver mis turnos", "tenant-1", null);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("view_agenda_bookings_by_contact");
        verifyNoInteractions(languageModel);
    }

    @Test
    void classify_miniLlm_returnsViewAgendaBookingsByContact() {
        when(languageModel.generate(any(LlmRequest.class))).thenReturn(LlmResponse.ok("ACCION_CRM view_agenda_bookings_by_contact"));
        IntentClassification r = service.classify("Consulta de appointments registrados a mi nombre", "1", null);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("view_agenda_bookings_by_contact");
        verify(languageModel).generate(any(LlmRequest.class));
    }
}

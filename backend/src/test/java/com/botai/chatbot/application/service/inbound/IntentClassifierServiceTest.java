package com.botai.chatbot.application.service.inbound;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.LlmRequest;
import com.botai.chatbot.domain.model.LlmResponse;
import com.botai.chatbot.domain.service.LanguageModel;
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

    private static ConversationState activeBookingState() {
        return ConversationState.builder()
            .currentIntent("book_appointment")
            .build();
    }

    @Test
    void classify_activeBooking_typoContainingAgendar_skipsMiniLlm() {
        IntentClassification r = service.classify("Quwornagendar una cita", "1", activeBookingState());
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("book_appointment");
        verifyNoInteractions(languageModel);
    }

    @Test
    void classify_activeBooking_horasDisponibles_skipsMiniLlm() {
        IntentClassification r = service.classify("Que horas tienes disponible?", "1", activeBookingState());
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        assertThat(r.getActionId()).contains("book_appointment");
        verifyNoInteractions(languageModel);
    }

    @Test
    void classify_activeBooking_longText_usesMiniLlm() {
        String longText = "x".repeat(250);
        when(languageModel.generate(any(LlmRequest.class))).thenReturn(LlmResponse.ok("PREGUNTA_GENERAL"));
        IntentClassification r = service.classify(longText, "1", activeBookingState());
        assertThat(r).isInstanceOf(IntentClassification.GeneralQuestion.class);
        verify(languageModel).generate(any(LlmRequest.class));
    }

    @Test
    void classify_withoutActiveBooking_typoCallsMiniLlm() {
        when(languageModel.generate(any(LlmRequest.class))).thenReturn(LlmResponse.ok("ACCION_CRM book_appointment"));
        ConversationState noIntent = ConversationState.builder().build();
        IntentClassification r = service.classify("Quwornagendar una cita", "1", noIntent);
        assertThat(r).isInstanceOf(IntentClassification.CrmAction.class);
        verify(languageModel).generate(any(LlmRequest.class));
    }
}

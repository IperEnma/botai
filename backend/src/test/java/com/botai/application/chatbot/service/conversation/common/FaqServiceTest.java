package com.botai.application.chatbot.service.conversation.common;

import com.botai.domain.chatbot.model.FaqEntry;
import com.botai.domain.chatbot.model.FaqResponseMode;
import com.botai.domain.chatbot.repository.FaqRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FaqServiceTest {

    @Mock
    private FaqRepository faqRepository;

    @InjectMocks
    private FaqService faqService;

    @Test
    void fixedMatchReturnsLiteralFaq() {
        when(faqRepository.findAllActive()).thenReturn(List.of(
            new FaqEntry("horario", "horario, abren", "Abrimos de 9 a 18", false, FaqResponseMode.FIXED)
        ));
        assertThat(faqService.findFixedMatch("¿Cuál es el horario?")).isPresent();
        assertThat(faqService.findFixedMatch("¿Cuál es el horario?").orElseThrow().response())
            .isEqualTo("Abrimos de 9 a 18");
    }

    @Test
    void ragHintDoesNotShortCircuitFixedPath() {
        when(faqRepository.findAllActive()).thenReturn(List.of(
            new FaqEntry("politica", "reembolso", "No hacemos reembolsos parciales", false, FaqResponseMode.RAG_HINT)
        ));
        assertThat(faqService.findFixedMatch("quiero un reembolso")).isEmpty();
        assertThat(faqService.findRagHints("quiero un reembolso")).hasSize(1);
    }
}

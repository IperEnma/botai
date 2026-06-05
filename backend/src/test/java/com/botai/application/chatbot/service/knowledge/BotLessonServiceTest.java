package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.BotLesson;
import com.botai.domain.chatbot.repository.BotLessonRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BotLessonServiceTest {

    @Mock
    private BotLessonRepository botLessonRepository;

    @InjectMocks
    private BotLessonService botLessonService;

    @Test
    void activatesLessonWhenKeywordMatches() {
        when(botLessonRepository.findAllActiveByTenantId("t1")).thenReturn(List.of(
            new BotLesson("Tono reserva", "agendar,reservar", "Nunca digas que llamen por teléfono; usa el enlace web.")
        ));
        List<BotLesson> active = botLessonService.findActiveForQuery("t1", "Quiero agendar un turno");
        assertThat(active).hasSize(1);
        assertThat(active.get(0).getContent()).contains("enlace web");
    }

    @Test
    void skipsLessonWhenNoKeywordMatch() {
        when(botLessonRepository.findAllActiveByTenantId("t1")).thenReturn(List.of(
            new BotLesson("Cancelaciones", "cancelar", "Política de cancelación 24h.")
        ));
        assertThat(botLessonService.findActiveForQuery("t1", "¿Cuál es el horario?")).isEmpty();
    }
}

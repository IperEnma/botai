package com.botai.infrastructure.chatbot.ai;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RagAttributionHintsTest {

    @Test
    void mapsTopicsToNaturalPhrasesWithoutTechnicalTerms() {
        assertThat(RagAttributionHints.phraseForTopic("Agenda: Horarios"))
            .contains("horarios de atención")
            .doesNotContain("Agenda:");
        String instruction = RagAttributionHints.promptInstructionForChunks(List.of(
            new KnowledgeChunk("Agenda: Horarios", "Lunes a viernes 9-18", "")
        ));
        assertThat(instruction).contains("horarios de atención");
        assertThat(instruction).doesNotContain("Agenda:");
    }

    @Test
    void phraseForTopicCoversServices() {
        assertThat(RagAttributionHints.phraseForTopic("Agenda: Servicios"))
            .contains("servicios");
    }
}

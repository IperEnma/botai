package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.model.KnowledgeChunkHit;
import com.botai.domain.chatbot.model.RagRetrievalResult;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.embedding.Embedding;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KnowledgeServicePhase1Test {

    private static final String TENANT = "tenant-1";

    @Mock
    private KnowledgeRepository knowledgeRepository;
    @Mock
    private EmbeddingModel embeddingModel;
    @Mock
    private EmbeddingResponse embeddingResponse;

    private KnowledgeService service;

    private void stubEmbeddingVector() {
        when(embeddingModel.embedForResponse(any())).thenReturn(embeddingResponse);
        when(embeddingResponse.getResults()).thenReturn(
                List.of(new Embedding(new float[] {0.1f, 0.2f, 0.3f}, 0)));
    }

    @BeforeEach
    void setUp() {
        service = new KnowledgeService(
                knowledgeRepository,
                embeddingModel,
                0.0,
                () -> 0,
                true,
                2,
                0.52,
                0.40,
                2);
    }

    @Test
    void retrieveForTurn_cragRejectsLowSimilarityHits() {
        KnowledgeChunk chunk = new KnowledgeChunk("Agenda: Horarios", "Lun-Vie 9-18", "horario");
        stubEmbeddingVector();
        when(knowledgeRepository.findRelevantBySimilarityScored(any(), anyInt(), eq(TENANT), eq(null), any()))
                .thenReturn(List.of(new KnowledgeChunkHit(chunk, 0.85)));

        RagRetrievalResult result = service.retrieveForTurn("horarios", 3, TENANT, List.of());

        assertThat(result.cragRejected()).isTrue();
        assertThat(result.chunks()).isEmpty();
    }

    @Test
    void retrieveForTurn_acceptsHighSimilarityHits() {
        KnowledgeChunk chunk = new KnowledgeChunk("Agenda: Horarios", "Lun-Vie 9-18", "horario");
        stubEmbeddingVector();
        when(knowledgeRepository.findRelevantBySimilarityScored(any(), anyInt(), eq(TENANT), eq(null), any()))
                .thenReturn(List.of(new KnowledgeChunkHit(chunk, 0.12)));

        RagRetrievalResult result = service.retrieveForTurn("horarios", 3, TENANT, List.of());

        assertThat(result.cragRejected()).isFalse();
        assertThat(result.chunks()).hasSize(1);
        assertThat(result.avgSimilarity()).isGreaterThanOrEqualTo(0.52);
    }
}

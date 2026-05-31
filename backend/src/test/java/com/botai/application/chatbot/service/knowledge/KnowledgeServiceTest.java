package com.botai.application.chatbot.service.knowledge;

import com.botai.domain.chatbot.model.KnowledgeChunk;
import com.botai.domain.chatbot.repository.KnowledgeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KnowledgeServiceTest {

    private static final String TENANT = "tenant-1";

    @Mock
    private KnowledgeRepository knowledgeRepository;
    @Mock
    private EmbeddingModel embeddingModel;
    @Mock
    private EmbeddingResponse embeddingResponse;

    private KnowledgeService service;

    @BeforeEach
    void setUp() {
        service = new KnowledgeService(knowledgeRepository, embeddingModel, 0.0, () -> 0);
    }

    @Test
    void findRelevant_usesTextFallbackForBusinessNameWhenEmbeddingsEmpty() {
        KnowledgeChunk businessChunk = new KnowledgeChunk(
                "Agenda: Información del negocio",
                "Nombre comercial del negocio: Felito Barber",
                "nombre negocio");

        when(knowledgeRepository.countActiveByTenantId(TENANT)).thenReturn(1L);
        when(knowledgeRepository.findAllActiveByTenantId(TENANT)).thenReturn(List.of(businessChunk));
        when(embeddingModel.embedForResponse(any())).thenReturn(embeddingResponse);
        when(embeddingResponse.getResults()).thenReturn(List.of());

        List<KnowledgeChunk> result = service.findRelevant("Cómo se llaman?", 3, TENANT);

        assertThat(result).containsExactly(businessChunk);
        verify(knowledgeRepository).findAllActiveByTenantId(TENANT);
    }

    @Test
    void findRelevant_returnsEmptyWhenNoActiveChunks() {
        when(knowledgeRepository.countActiveByTenantId(TENANT)).thenReturn(0L);
        when(embeddingModel.embedForResponse(any())).thenReturn(embeddingResponse);
        when(embeddingResponse.getResults()).thenReturn(List.of());

        List<KnowledgeChunk> result = service.findRelevant("horarios", 3, TENANT);

        assertThat(result).isEmpty();
        verify(knowledgeRepository, never()).findAllActiveByTenantId(TENANT);
    }
}

package com.botai.agenda.application.usecase.search;

import com.botai.agenda.domain.model.BusinessSummary;
import com.botai.agenda.domain.repository.BusinessSearchRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListBusinessesByCategoryUseCaseTest {

    private BusinessSearchRepository searchRepository;
    private ListBusinessesByCategoryUseCase useCase;

    @BeforeEach
    void setUp() {
        searchRepository = mock(BusinessSearchRepository.class);
        useCase = new ListBusinessesByCategoryUseCase(searchRepository);
    }

    @Test
    void delegaAlRepoConSlugLimitYOffsetDentroDeRango() {
        List<BusinessSummary> expected = List.of(new BusinessSummary(
                UUID.randomUUID(), "t1", "Yoga Studio", null, List.of("yoga"), null));
        when(searchRepository.findByCategorySlug("yoga", 10, 0)).thenReturn(expected);

        List<BusinessSummary> result = useCase.execute("yoga", 10, 0);

        assertSame(expected, result);
        verify(searchRepository).findByCategorySlug("yoga", 10, 0);
    }

    @Test
    void limitMayorA100SeCapsA100() {
        when(searchRepository.findByCategorySlug("yoga", 100, 5)).thenReturn(List.of());

        useCase.execute("yoga", 9999, 5);

        verify(searchRepository).findByCategorySlug("yoga", 100, 5);
    }

    @Test
    void limitCeroOMenorSubeAlMinimo1() {
        when(searchRepository.findByCategorySlug("yoga", 1, 0)).thenReturn(List.of());

        useCase.execute("yoga", 0, 0);

        verify(searchRepository).findByCategorySlug("yoga", 1, 0);
    }

    @Test
    void offsetNegativoSeNormalizaA0() {
        when(searchRepository.findByCategorySlug("yoga", 10, 0)).thenReturn(List.of());

        useCase.execute("yoga", 10, -25);

        verify(searchRepository).findByCategorySlug("yoga", 10, 0);
    }

    @Test
    void listaVaciaSeDevuelveIntacta() {
        when(searchRepository.findByCategorySlug("x", 10, 0)).thenReturn(List.of());

        List<BusinessSummary> result = useCase.execute("x", 10, 0);

        assertEquals(0, result.size());
    }
}

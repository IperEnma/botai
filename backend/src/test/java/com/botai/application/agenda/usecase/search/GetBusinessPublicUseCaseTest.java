package com.botai.application.agenda.usecase.search;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.BusinessSummary;
import com.botai.domain.agenda.repository.BusinessSearchRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GetBusinessPublicUseCaseTest {

    private BusinessSearchRepository searchRepository;
    private GetBusinessPublicUseCase useCase;

    @BeforeEach
    void setUp() {
        searchRepository = mock(BusinessSearchRepository.class);
        useCase = new GetBusinessPublicUseCase(searchRepository);
    }

    @Test
    void devuelveElResumenCuandoExiste() {
        UUID id = UUID.randomUUID();
        BusinessSummary expected = new BusinessSummary(
                id, "tenant-1", "Barbería Don Paco", "La mejor del barrio",
                List.of("barberia"), null, "barberia-don-paco");
        when(searchRepository.findPublicById(id)).thenReturn(expected);

        BusinessSummary result = useCase.execute(id);

        assertEquals(expected, result);
    }

    @Test
    void cuandoElAdapterDevuelveNullLanzaBusinessNotFound() {
        UUID id = UUID.randomUUID();
        when(searchRepository.findPublicById(id)).thenReturn(null);

        assertThrows(BusinessNotFoundException.class, () -> useCase.execute(id));
    }
}

package com.botai.agenda.application.usecase.search;

import com.botai.agenda.domain.model.BusinessSummary;
import com.botai.agenda.domain.repository.BusinessSearchRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests del caso de uso del buscador público.
 *
 * <p>Observación: el use case actual NO normaliza el término (no hace trim
 * ni lowercase) — simplemente delega en el adapter pasando el string tal cual
 * y solo acota los parámetros de paginación a rangos sanos. Los tests reflejan
 * el comportamiento real.</p>
 */
class SearchBusinessesUseCaseTest {

    private BusinessSearchRepository searchRepo;
    private SearchBusinessesUseCase useCase;

    @BeforeEach
    void setUp() {
        searchRepo = mock(BusinessSearchRepository.class);
        useCase = new SearchBusinessesUseCase(searchRepo,
                new io.micrometer.core.instrument.simple.SimpleMeterRegistry());
    }

    @Test
    void pasaElTerminoYTenantIdAlAdapter() {
        when(searchRepo.searchByTerm(anyString(), anyString(), anyInt(), anyInt()))
                .thenReturn(List.of());

        useCase.execute("uñas", "tenant-1", 10, 0);

        ArgumentCaptor<String> term = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> tenant = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Integer> limit = ArgumentCaptor.forClass(Integer.class);
        ArgumentCaptor<Integer> offset = ArgumentCaptor.forClass(Integer.class);

        verify(searchRepo).searchByTerm(term.capture(), tenant.capture(),
                limit.capture(), offset.capture());

        assertEquals("uñas", term.getValue());
        assertEquals("tenant-1", tenant.getValue());
        assertEquals(10, limit.getValue());
        assertEquals(0, offset.getValue());
    }

    @Test
    void aceptaTenantIdNullParaBusquedaGlobal() {
        when(searchRepo.searchByTerm(anyString(), any(), anyInt(), anyInt()))
                .thenReturn(List.of());

        useCase.execute("yoga", null, 5, 0);

        verify(searchRepo).searchByTerm(eq("yoga"), isNull(), eq(5), eq(0));
    }

    @Test
    void clampeaElLimiteSuperiorA100() {
        when(searchRepo.searchByTerm(anyString(), anyString(), anyInt(), anyInt()))
                .thenReturn(List.of());

        useCase.execute("corte", "tenant-1", 999, 0);

        ArgumentCaptor<Integer> limit = ArgumentCaptor.forClass(Integer.class);
        verify(searchRepo).searchByTerm(anyString(), anyString(), limit.capture(), anyInt());
        assertEquals(100, limit.getValue(),
                "El use case debe acotar el límite a un máximo razonable de 100");
    }

    @Test
    void clampeaLimiteInferiorA1() {
        when(searchRepo.searchByTerm(anyString(), anyString(), anyInt(), anyInt()))
                .thenReturn(List.of());

        useCase.execute("corte", "tenant-1", 0, 0);

        ArgumentCaptor<Integer> limit = ArgumentCaptor.forClass(Integer.class);
        verify(searchRepo).searchByTerm(anyString(), anyString(), limit.capture(), anyInt());
        assertEquals(1, limit.getValue(),
                "El use case debe acotar el límite mínimo a 1");
    }

    @Test
    void clampeaOffsetNegativoACero() {
        when(searchRepo.searchByTerm(anyString(), anyString(), anyInt(), anyInt()))
                .thenReturn(List.of());

        useCase.execute("corte", "tenant-1", 10, -99);

        ArgumentCaptor<Integer> offset = ArgumentCaptor.forClass(Integer.class);
        verify(searchRepo).searchByTerm(anyString(), anyString(), anyInt(), offset.capture());
        assertEquals(0, offset.getValue(),
                "Un offset negativo debe sanitizarse a 0");
    }

    @Test
    void devuelveLosResultadosDelAdapter() {
        BusinessSummary summary = new BusinessSummary(
                UUID.randomUUID(), "tenant-1", "Uñas Felices", "Manicura",
                List.of("manicure"), null
        );
        when(searchRepo.searchByTerm(anyString(), anyString(), anyInt(), anyInt()))
                .thenReturn(List.of(summary));

        List<BusinessSummary> result = useCase.execute("uñas", "tenant-1", 10, 0);

        assertEquals(1, result.size());
        assertEquals("Uñas Felices", result.get(0).getNombre());
    }
}

package com.botai.application.agenda.usecase.feature;

import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GetTenantFeaturesUseCaseTest {

    private TenantConfigRepository repo;
    private GetTenantFeaturesUseCase useCase;

    @BeforeEach
    void setUp() {
        repo = mock(TenantConfigRepository.class);
        useCase = new GetTenantFeaturesUseCase(repo);
    }

    @Test
    void devuelveDefaultsFailClosedSiNoHayRegistro() {
        when(repo.findByTenantId("tenant-nuevo")).thenReturn(Optional.empty());

        TenantConfig result = useCase.execute("tenant-nuevo");

        assertEquals("tenant-nuevo", result.getTenantId());
        assertFalse(result.isAgendaEnabled(),
                "Sin registro, el módulo debe venir apagado (fail-closed)");
        assertTrue(result.isPublicSearchEnabled());
        assertTrue(result.isLoyaltyEngineEnabled());
        assertTrue(result.isAutoNotifications());
    }

    @Test
    void devuelveLaConfigPersistidaSiExiste() {
        TenantConfig persisted = new TenantConfig("tenant-1", true, true, false, true);
        when(repo.findByTenantId("tenant-1")).thenReturn(Optional.of(persisted));

        TenantConfig result = useCase.execute("tenant-1");

        assertEquals("tenant-1", result.getTenantId());
        assertTrue(result.isAgendaEnabled(),
                "Debe retornar el flag persistido, no el default");
        assertFalse(result.isLoyaltyEngineEnabled(),
                "Un flag persistido como false debe respetarse");
    }
}

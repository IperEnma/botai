package com.botai.agenda.application.usecase.feature;

import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.domain.repository.TenantConfigRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UpdateTenantFeaturesUseCaseTest {

    private TenantConfigRepository tenantConfigRepository;
    private UpdateTenantFeaturesUseCase useCase;

    private final String tenantId = "tenant-abc";

    @BeforeEach
    void setUp() {
        tenantConfigRepository = mock(TenantConfigRepository.class);
        useCase = new UpdateTenantFeaturesUseCase(tenantConfigRepository);
    }

    @Test
    void siNoExisteCreaConDefaultsYAplicaLosCamposProvistos() {
        when(tenantConfigRepository.findByTenantId(tenantId)).thenReturn(Optional.empty());
        when(tenantConfigRepository.save(any(TenantConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // defaults: agendaEnabled=false, publicSearch=true, loyalty=true, notif=true
        useCase.execute(tenantId, true, null, null, null);

        ArgumentCaptor<TenantConfig> captor = ArgumentCaptor.forClass(TenantConfig.class);
        verify(tenantConfigRepository).save(captor.capture());
        TenantConfig saved = captor.getValue();

        assertEquals(tenantId, saved.getTenantId());
        assertTrue(saved.isAgendaEnabled(), "Debe reflejar el flag recién provisto");
        assertTrue(saved.isPublicSearchEnabled(), "Conserva default");
        assertTrue(saved.isLoyaltyEngineEnabled(), "Conserva default");
        assertTrue(saved.isAutoNotifications(), "Conserva default");
    }

    @Test
    void siExisteAplicaSemanticaPatchIgnorandoNulos() {
        TenantConfig existing = new TenantConfig(tenantId, true, true, true, true);
        when(tenantConfigRepository.findByTenantId(tenantId)).thenReturn(Optional.of(existing));
        when(tenantConfigRepository.save(any(TenantConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(tenantId, null, false, null, false);

        ArgumentCaptor<TenantConfig> captor = ArgumentCaptor.forClass(TenantConfig.class);
        verify(tenantConfigRepository).save(captor.capture());
        TenantConfig saved = captor.getValue();

        assertTrue(saved.isAgendaEnabled(), "null → conserva el valor actual");
        assertFalse(saved.isPublicSearchEnabled(), "false → lo apaga");
        assertTrue(saved.isLoyaltyEngineEnabled(), "null → conserva el valor actual");
        assertFalse(saved.isAutoNotifications(), "false → lo apaga");
    }

    @Test
    void todosLosCamposNullDejanLaConfigIgual() {
        TenantConfig existing = new TenantConfig(tenantId, true, false, true, false);
        when(tenantConfigRepository.findByTenantId(tenantId)).thenReturn(Optional.of(existing));
        when(tenantConfigRepository.save(any(TenantConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(tenantId, null, null, null, null);

        ArgumentCaptor<TenantConfig> captor = ArgumentCaptor.forClass(TenantConfig.class);
        verify(tenantConfigRepository).save(captor.capture());
        TenantConfig saved = captor.getValue();

        assertTrue(saved.isAgendaEnabled());
        assertFalse(saved.isPublicSearchEnabled());
        assertTrue(saved.isLoyaltyEngineEnabled());
        assertFalse(saved.isAutoNotifications());
    }
}

package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UpdateBusinessUseCaseTest {

    private BusinessRepository businessRepository;
    private UpdateBusinessUseCase useCase;

    private final String tenantId = "tenant-42";
    private final UUID businessId = UUID.randomUUID();
    private final UUID ownerId = UUID.randomUUID();
    private final LocalDateTime created = LocalDateTime.of(2026, 1, 1, 10, 0);
    private final LocalDateTime updated = LocalDateTime.of(2026, 1, 2, 10, 0);

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        useCase = new UpdateBusinessUseCase(businessRepository);
    }

    private Business existing() {
        return new Business(
                businessId, tenantId, "Barbería Original", "Desc original",
                ownerId, List.of("barber", "cortes"), true, null, null, null, null, null, null, null, null, created, updated);
    }

    @Test
    void actualizaSoloCamposProvistosYMantieneLosOtros() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(existing()));
        when(businessRepository.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));

        Business result = useCase.execute(
                tenantId, businessId,
                "Nuevo Nombre",
                null,         // descripcion: null → se mantiene
                null,         // tags: null → se mantiene
                null,         // activo: null → se mantiene
                null,         // logoUrl
                null,         // colorPrimario
                null,         // instagramUrl
                null,         // tiktokUrl
                null,         // facebookUrl
                null,         // colorFondo
                null          // fontFamily
        );

        ArgumentCaptor<Business> captor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepository).save(captor.capture());
        Business saved = captor.getValue();

        assertEquals("Nuevo Nombre", saved.getNombre());
        assertEquals("Desc original", saved.getDescripcion());
        assertEquals(List.of("barber", "cortes"), saved.getSearchTags());
        assertTrue(saved.isActivo());
        assertEquals(businessId, result.getId());
        assertEquals(tenantId, saved.getTenantId());
        assertEquals(ownerId, saved.getOwnerUserId());
        assertEquals(created, saved.getCreatedAt(), "createdAt no se reescribe desde el use case");
    }

    @Test
    void actualizaDescripcionYTagsYActivo() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.of(existing()));
        when(businessRepository.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));

        useCase.execute(tenantId, businessId,
                null,
                "Nueva descripción",
                List.of("nuevo"),
                false,
                null, null, null, null, null, null, null);

        ArgumentCaptor<Business> captor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepository).save(captor.capture());
        Business saved = captor.getValue();

        assertEquals("Barbería Original", saved.getNombre());
        assertEquals("Nueva descripción", saved.getDescripcion());
        assertEquals(List.of("nuevo"), saved.getSearchTags());
        assertFalse(saved.isActivo());
    }

    @Test
    void siNoExisteElNegocioParaElTenantLanzaNotFound() {
        when(businessRepository.findByIdAndTenantId(businessId, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(tenantId, businessId, "X", null, null, null, null, null, null, null, null, null, null));

        verify(businessRepository, never()).save(any(Business.class));
    }
}

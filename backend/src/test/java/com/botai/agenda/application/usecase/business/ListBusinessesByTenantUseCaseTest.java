package com.botai.agenda.application.usecase.business;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.repository.BusinessRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ListBusinessesByTenantUseCaseTest {

    private BusinessRepository businessRepository;
    private ListBusinessesByTenantUseCase useCase;

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        useCase = new ListBusinessesByTenantUseCase(businessRepository);
    }

    private Business biz(UUID id, String nombre, String tenant) {
        return new Business(id, tenant, nombre, null, null, List.of(), true, null, null,
                null, null, null, null, null, null, LocalDateTime.now(), LocalDateTime.now());
    }

    @Test
    void listAllDelegaAlRepoConElTenant() {
        String tenantId = "tenant-1";
        List<Business> expected = List.of(
                biz(UUID.randomUUID(), "A", tenantId),
                biz(UUID.randomUUID(), "B", tenantId));
        when(businessRepository.findAllByTenantId(tenantId)).thenReturn(expected);

        List<Business> result = useCase.listAll(tenantId);

        assertEquals(expected, result);
    }

    @Test
    void findOneDevuelveElNegocioSiExisteParaElTenant() {
        String tenantId = "tenant-1";
        UUID id = UUID.randomUUID();
        Business expected = biz(id, "B", tenantId);
        when(businessRepository.findByIdAndTenantId(id, tenantId))
                .thenReturn(Optional.of(expected));

        Business result = useCase.findOne(tenantId, id);

        assertEquals(expected, result);
    }

    @Test
    void findOneLanzaNotFoundCuandoElNegocioNoPertenece() {
        String tenantId = "tenant-1";
        UUID id = UUID.randomUUID();
        when(businessRepository.findByIdAndTenantId(id, tenantId))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class, () -> useCase.findOne(tenantId, id));
    }
}

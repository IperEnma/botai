package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ListBusinessServicesUseCaseTest {

    private BusinessRepository businessRepository;
    private ServiceRepository serviceRepository;
    private ListBusinessServicesUseCase useCase;

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        serviceRepository = mock(ServiceRepository.class);
        useCase = new ListBusinessServicesUseCase(businessRepository, serviceRepository);
    }

    @Test
    void delegaAlRepoSoloLosActivosDelNegocio() {
        UUID businessId = UUID.randomUUID();
        List<Service> expected = List.of(
                new Service(UUID.randomUUID(), businessId, "Corte", null,
                        30, new BigDecimal("15.00"), true, null,
                        LocalDateTime.now(), LocalDateTime.now()));
        when(serviceRepository.findAllActiveByBusinessId(businessId)).thenReturn(expected);

        List<Service> result = useCase.execute(businessId);

        assertSame(expected, result);
        verify(serviceRepository).findAllActiveByBusinessId(businessId);
    }
}

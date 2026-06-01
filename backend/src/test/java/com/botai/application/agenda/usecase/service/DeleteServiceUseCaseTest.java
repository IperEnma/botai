package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DeleteServiceUseCaseTest {

    private BusinessRepository businessRepository;
    private ServiceRepository serviceRepository;
    private DeleteServiceUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID SERVICE_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        serviceRepository = mock(ServiceRepository.class);
        useCase = new DeleteServiceUseCase(businessRepository, serviceRepository);

        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
    }

    @Test
    void eliminarServicio_llamaSoftDelete() {
        when(serviceRepository.findById(SERVICE_ID))
                .thenReturn(Optional.of(service(BUSINESS_ID)));

        useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID);

        verify(serviceRepository).softDelete(SERVICE_ID);
    }

    @Test
    void businessInvalido_noBorraNada() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID));
        verify(serviceRepository, never()).softDelete(SERVICE_ID);
    }

    @Test
    void servicioNoExiste_lanzaServiceNotFoundException() {
        when(serviceRepository.findById(SERVICE_ID)).thenReturn(Optional.empty());

        assertThrows(ServiceNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID));
        verify(serviceRepository, never()).softDelete(SERVICE_ID);
    }

    @Test
    void servicioDeOtroNegocio_lanzaServiceNotFoundException() {
        UUID otroBusiness = UUID.randomUUID();
        when(serviceRepository.findById(SERVICE_ID))
                .thenReturn(Optional.of(service(otroBusiness)));

        assertThrows(ServiceNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID));
        verify(serviceRepository, never()).softDelete(SERVICE_ID);
    }

    private Service service(UUID businessId) {
        return new Service(SERVICE_ID, businessId, "Corte", null, 45,
                BigDecimal.valueOf(1000), true, ServiceSchedulingMode.GENERAL, null, null, null);
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }
}

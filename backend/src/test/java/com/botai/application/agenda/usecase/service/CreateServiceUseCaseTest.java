package com.botai.application.agenda.usecase.service;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CreateServiceUseCaseTest {

    private BusinessRepository businessRepository;
    private ServiceRepository serviceRepository;
    private CreateServiceUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        serviceRepository = mock(ServiceRepository.class);
        useCase = new CreateServiceUseCase(businessRepository, serviceRepository);

        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        when(serviceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void crearServicio_guardaConAtributosCorrectos() {
        Service result = useCase.execute(TENANT, BUSINESS_ID, "Corte", "Corte de cabello", 45,
                BigDecimal.valueOf(1500));

        assertEquals("Corte", result.getNombre());
        assertEquals(BUSINESS_ID, result.getBusinessId());
        assertEquals(45, result.getDuracionMin());
        assertEquals(BigDecimal.valueOf(1500), result.getPrecio());
        assertTrue(result.isActivo());
    }

    @Test
    void crearServicio_businessInvalido_lanzaExcepcion() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, "X", null, 30, null));
        verify(serviceRepository, never()).save(any());
    }

    @Test
    void crearServicio_sinPrecio_sePermite() {
        Service result = useCase.execute(TENANT, BUSINESS_ID, "Consulta", null, 60, null);

        assertEquals("Consulta", result.getNombre());
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }
}

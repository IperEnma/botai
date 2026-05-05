package com.botai.agenda.application.usecase.service;

import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.ServiceNotFoundException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.Service;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.ServiceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UpdateServiceUseCaseTest {

    private BusinessRepository businessRepository;
    private ServiceRepository serviceRepository;
    private UpdateServiceUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID SERVICE_ID = UUID.randomUUID();
    private final LocalDateTime NOW = LocalDateTime.of(2026, 5, 1, 10, 0);

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        serviceRepository = mock(ServiceRepository.class);
        useCase = new UpdateServiceUseCase(businessRepository, serviceRepository);

        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
        when(serviceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void actualizarServicio_cambiaCamposCorrectos() {
        when(serviceRepository.findById(SERVICE_ID)).thenReturn(Optional.of(service(BUSINESS_ID)));

        Service result = useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID,
                "Nuevo nombre", "Nueva desc", 60, BigDecimal.valueOf(2000), false);

        assertEquals("Nuevo nombre", result.getNombre());
        assertEquals(60, result.getDuracionMin());
        assertEquals(BigDecimal.valueOf(2000), result.getPrecio());
        assertEquals(false, result.isActivo());
        assertEquals(SERVICE_ID, result.getId());
    }

    @Test
    void actualizarServicio_preservaCreatedAt() {
        when(serviceRepository.findById(SERVICE_ID)).thenReturn(Optional.of(service(BUSINESS_ID)));

        Service result = useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID,
                "X", null, 30, null, true);

        assertEquals(NOW.minusDays(5), result.getCreatedAt());
    }

    @Test
    void businessInvalido_lanzaExcepcion() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID, "X", null, 30, null, true));
        verify(serviceRepository, never()).save(any());
    }

    @Test
    void servicioNoExiste_lanzaServiceNotFoundException() {
        when(serviceRepository.findById(SERVICE_ID)).thenReturn(Optional.empty());

        assertThrows(ServiceNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID, "X", null, 30, null, true));
    }

    @Test
    void servicioDeOtroNegocio_lanzaServiceNotFoundException() {
        UUID otroBusiness = UUID.randomUUID();
        when(serviceRepository.findById(SERVICE_ID)).thenReturn(Optional.of(service(otroBusiness)));

        assertThrows(ServiceNotFoundException.class,
                () -> useCase.execute(TENANT, BUSINESS_ID, SERVICE_ID, "X", null, 30, null, true));
    }

    private Service service(UUID businessId) {
        return new Service(SERVICE_ID, businessId, "Original", null, 45,
                BigDecimal.valueOf(1000), true, null,
                NOW.minusDays(5), NOW.minusDays(5));
    }

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio", null, null, null,
                true, null, null, null, null, null, null, null, null, null, null);
    }
}

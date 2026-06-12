package com.botai.infrastructure.agenda.security;

import com.botai.application.agenda.security.AgendaUserPrincipal;
import com.botai.domain.agenda.exception.AgendaTenantNotResolvedException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgendaCurrentTenantServiceTest {

    @Mock
    private BusinessRepository businessRepository;
    @Mock
    private AgendaUserContext userContext;
    @InjectMocks
    private AgendaCurrentTenantService service;

    @Test
    void requireBusinessOwnedByCurrentTenant_negocioDeOtroTenant_lanza404() {
        UUID businessId = UUID.randomUUID();
        when(userContext.principal()).thenReturn(principal("tenant-a"));
        when(businessRepository.findByIdAndTenantId(businessId, "tenant-a"))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> service.requireBusinessOwnedByCurrentTenant(businessId));
    }

    @Test
    void requireBusinessOwnedByCurrentTenant_negocioPropio_devuelveBusiness() {
        UUID businessId = UUID.randomUUID();
        Business business = new Business(
                businessId, "tenant-a", "Salon", null, null, List.of(), true,
                null, null, null, null, null, null, null, null, null, null,
                null, null, null);
        when(userContext.principal()).thenReturn(principal("tenant-a"));
        when(businessRepository.findByIdAndTenantId(businessId, "tenant-a"))
                .thenReturn(Optional.of(business));

        Business result = service.requireBusinessOwnedByCurrentTenant(businessId);
        assertEquals(businessId, result.getId());
        assertEquals("tenant-a", result.getTenantId());
    }

    @Test
    void requireTenantId_sinCuentaAgenda_lanzaTenantNotResolved() {
        when(userContext.principal()).thenReturn(AgendaUserPrincipal.anonymous());

        assertThrows(AgendaTenantNotResolvedException.class, service::requireTenantId);
    }

    @Test
    void requireTenantId_miembroInvitado_resuelveTenant() {
        when(userContext.principal()).thenReturn(principal("tenant-a"));

        assertEquals("tenant-a", service.requireTenantId());
    }

    private static AgendaUserPrincipal principal(String tenantId) {
        return new AgendaUserPrincipal(UUID.randomUUID(), "user@test.com", tenantId, List.of());
    }
}

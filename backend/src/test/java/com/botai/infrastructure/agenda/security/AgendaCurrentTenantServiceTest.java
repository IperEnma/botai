package com.botai.infrastructure.agenda.security;

import com.botai.domain.agenda.exception.AgendaTenantNotResolvedException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgendaCurrentTenantServiceTest {

    @Mock
    private TenantAccountRepository tenantAccountRepository;
    @Mock
    private BusinessRepository businessRepository;
    @InjectMocks
    private AgendaCurrentTenantService service;

    @Test
    void requireBusinessOwnedByCurrentTenant_negocioDeOtroTenant_lanza404() {
        UUID businessId = UUID.randomUUID();
        when(tenantAccountRepository.findByEmail("owner@test.com"))
                .thenReturn(Optional.of(tenantAccount("tenant-a")));
        when(businessRepository.findByIdAndTenantId(businessId, "tenant-a"))
                .thenReturn(Optional.empty());

        try (var ignored = mockStatic(AgendaAuthContext.class)) {
            ignored.when(AgendaAuthContext::currentJwt).thenReturn(jwtWithEmail("owner@test.com"));
            assertThrows(BusinessNotFoundException.class,
                    () -> service.requireBusinessOwnedByCurrentTenant(businessId));
        }
    }

    @Test
    void requireBusinessOwnedByCurrentTenant_negocioPropio_devuelveBusiness() {
        UUID businessId = UUID.randomUUID();
        Business business = new Business(
                businessId, "tenant-a", "Salon", null, null, List.of(), true,
                null, null, null, null, null, null, null, null, null, null,
                null, null, null);
        when(tenantAccountRepository.findByEmail("owner@test.com"))
                .thenReturn(Optional.of(tenantAccount("tenant-a")));
        when(businessRepository.findByIdAndTenantId(businessId, "tenant-a"))
                .thenReturn(Optional.of(business));

        try (var ignored = mockStatic(AgendaAuthContext.class)) {
            ignored.when(AgendaAuthContext::currentJwt).thenReturn(jwtWithEmail("owner@test.com"));
            Business result = service.requireBusinessOwnedByCurrentTenant(businessId);
            assertEquals(businessId, result.getId());
            assertEquals("tenant-a", result.getTenantId());
        }
    }

    @Test
    void requireTenantId_sinCuentaAgenda_lanzaTenantNotResolved() {
        try (var ignored = mockStatic(AgendaAuthContext.class)) {
            ignored.when(AgendaAuthContext::currentJwt).thenReturn(jwtWithEmail("nuevo@gmail.com"));
            when(tenantAccountRepository.findByEmail("nuevo@gmail.com")).thenReturn(Optional.empty());
            when(tenantAccountRepository.findByGoogleLinkedEmail("nuevo@gmail.com")).thenReturn(Optional.empty());
            assertThrows(AgendaTenantNotResolvedException.class, service::requireTenantId);
        }
    }

    private static TenantAccount tenantAccount(String tenantId) {
        return new TenantAccount(
                tenantId, "Owner", "owner@test.com", null, null, null, "CODE", true, null, null);
    }

    private static Jwt jwtWithEmail(String email) {
        return Jwt.withTokenValue("test")
                .header("alg", "none")
                .claim("email", email)
                .build();
    }
}

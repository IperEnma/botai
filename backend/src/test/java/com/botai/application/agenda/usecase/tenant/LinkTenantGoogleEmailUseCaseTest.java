package com.botai.application.agenda.usecase.tenant;

import com.botai.application.agenda.dto.TenantAdminContextResponse;
import com.botai.domain.agenda.exception.TenantAccessCodeNotFoundException;
import com.botai.domain.agenda.exception.TenantGoogleLinkConflictException;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LinkTenantGoogleEmailUseCaseTest {

    private TenantAccountRepository repo;
    private LinkTenantGoogleEmailUseCase useCase;

    private static TenantAccount waAccount(String tenantId, String google) {
        return new TenantAccount(
                tenantId,
                "Ana",
                null,
                google,
                "59899123456",
                "+59899123456",
                "ABCD1234",
                true,
                LocalDateTime.now().minusDays(1),
                LocalDateTime.now().minusDays(1)
        );
    }

    @BeforeEach
    void setUp() {
        repo = mock(TenantAccountRepository.class);
        useCase = new LinkTenantGoogleEmailUseCase(repo);
        when(repo.save(any(TenantAccount.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void idempotente_siGoogleYaVinculado_devuelveMismoTenant() {
        when(repo.findByGoogleLinkedEmail("ana@gmail.com"))
                .thenReturn(Optional.of(waAccount("t-1", "ana@gmail.com")));

        TenantAdminContextResponse r = useCase.execute("  Ana@Gmail.com  ", "ABCD1234");

        assertEquals("t-1", r.tenantId());
        verify(repo, never()).findByAccessCode(anyString());
        verify(repo, never()).save(any());
    }

    @Test
    void codigoValido_persisteGoogleLinkedEmail() {
        when(repo.findByGoogleLinkedEmail("ana@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByEmail("ana@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByAccessCode("K7MN2PQX"))
                .thenReturn(Optional.of(waAccount("t-2", null)));
        when(repo.existsByGoogleLinkedEmail("ana@gmail.com")).thenReturn(false);

        TenantAdminContextResponse r = useCase.execute("ana@gmail.com", "k7mn2pqx");

        assertEquals("t-2", r.tenantId());
        verify(repo).save(any(TenantAccount.class));
    }

    @Test
    void codigoInexistente_lanzaNotFound() {
        when(repo.findByGoogleLinkedEmail("ana@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByEmail("ana@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByAccessCode("ZZZZZZZZ")).thenReturn(Optional.empty());

        assertThrows(TenantAccessCodeNotFoundException.class,
                () -> useCase.execute("ana@gmail.com", "ZZZZZZZZ"));
        verify(repo, never()).save(any());
    }

    @Test
    void negocioYaTieneOtroGoogle_lanzaConflict() {
        when(repo.findByGoogleLinkedEmail("nuevo@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByEmail("nuevo@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByAccessCode("ABCD1234"))
                .thenReturn(Optional.of(waAccount("t-3", "viejo@gmail.com")));

        assertThrows(TenantGoogleLinkConflictException.class,
                () -> useCase.execute("nuevo@gmail.com", "ABCD1234"));
    }
}

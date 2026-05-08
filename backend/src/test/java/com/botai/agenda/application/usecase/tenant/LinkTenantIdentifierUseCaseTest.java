package com.botai.agenda.application.usecase.tenant;

import com.botai.agenda.domain.exception.DuplicateTenantEmailException;
import com.botai.agenda.domain.exception.DuplicateTenantNumeroException;
import com.botai.agenda.domain.model.TenantAccount;
import com.botai.agenda.domain.repository.TenantAccountRepository;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class LinkTenantIdentifierUseCaseTest {

    private static TenantAccount baseAccountEmailLogin() {
        return new TenantAccount(
                "t-1",
                "Owner",
                "owner@tenant.com",
                "admin@gmail.com",
                null,
                null,
                "ABCDEFGH",
                true,
                LocalDateTime.now(),
                LocalDateTime.now()
        );
    }

    @Test
    void linkNumero_whenEmpty_updatesAccount() {
        TenantAccountRepository repo = mock(TenantAccountRepository.class);
        when(repo.findByEmail("admin@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByGoogleLinkedEmail("admin@gmail.com")).thenReturn(Optional.of(baseAccountEmailLogin()));
        when(repo.existsByNumero("59899112233")).thenReturn(false);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LinkTenantIdentifierUseCase useCase = new LinkTenantIdentifierUseCase(repo);

        assertDoesNotThrow(() -> useCase.execute("admin@gmail.com", null, "+598 99 112 233"));
        verify(repo).save(any());
    }

    @Test
    void linkNumero_whenAlreadyPresent_differentValue_conflict() {
        TenantAccountRepository repo = mock(TenantAccountRepository.class);
        TenantAccount acc = new TenantAccount(
                "t-1", "Owner", "a@b.com", null, "12345678", null, "ABCDEFGH", true, null, null
        );
        when(repo.findByEmail("a@b.com")).thenReturn(Optional.of(acc));

        LinkTenantIdentifierUseCase useCase = new LinkTenantIdentifierUseCase(repo);
        assertThrows(IllegalStateException.class,
                () -> useCase.execute("a@b.com", null, "87654321"));
        verify(repo, never()).save(any());
    }

    @Test
    void linkNumero_whenExistsOnOtherAccount_throwsDuplicate() {
        TenantAccountRepository repo = mock(TenantAccountRepository.class);
        when(repo.findByEmail("admin@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByGoogleLinkedEmail("admin@gmail.com")).thenReturn(Optional.of(baseAccountEmailLogin()));
        when(repo.existsByNumero("59899112233")).thenReturn(true);

        LinkTenantIdentifierUseCase useCase = new LinkTenantIdentifierUseCase(repo);
        assertThrows(DuplicateTenantNumeroException.class,
                () -> useCase.execute("admin@gmail.com", null, "59899112233"));
    }

    @Test
    void linkEmail_whenEmpty_updatesAccount() {
        TenantAccountRepository repo = mock(TenantAccountRepository.class);
        TenantAccount acc = new TenantAccount(
                "t-1", "Owner", null, "admin@gmail.com", "59899112233", null, "ABCDEFGH", true, null, null
        );
        when(repo.findByEmail("admin@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByGoogleLinkedEmail("admin@gmail.com")).thenReturn(Optional.of(acc));
        when(repo.existsByEmail("new@mail.com")).thenReturn(false);
        when(repo.existsByGoogleLinkedEmail("new@mail.com")).thenReturn(false);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LinkTenantIdentifierUseCase useCase = new LinkTenantIdentifierUseCase(repo);
        assertDoesNotThrow(() -> useCase.execute("admin@gmail.com", "new@mail.com", null));
        verify(repo).save(any());
    }

    @Test
    void linkEmail_whenExistsOnOtherAccount_throwsDuplicate() {
        TenantAccountRepository repo = mock(TenantAccountRepository.class);
        TenantAccount acc = new TenantAccount(
                "t-1", "Owner", null, "admin@gmail.com", "59899112233", null, "ABCDEFGH", true, null, null
        );
        when(repo.findByEmail("admin@gmail.com")).thenReturn(Optional.empty());
        when(repo.findByGoogleLinkedEmail("admin@gmail.com")).thenReturn(Optional.of(acc));
        when(repo.existsByEmail("x@y.com")).thenReturn(true);
        when(repo.existsByGoogleLinkedEmail("x@y.com")).thenReturn(false);

        LinkTenantIdentifierUseCase useCase = new LinkTenantIdentifierUseCase(repo);
        assertThrows(DuplicateTenantEmailException.class,
                () -> useCase.execute("admin@gmail.com", "x@y.com", null));
    }
}


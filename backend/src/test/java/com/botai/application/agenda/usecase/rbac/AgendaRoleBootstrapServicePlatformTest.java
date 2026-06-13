package com.botai.application.agenda.usecase.rbac;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgendaRoleBootstrapServicePlatformTest {

    private static final String OWNER_EMAIL = "jesushernandez1843@gmail.com";

    @Test
    void platformAdminEmailNoConfigurado_noHaceNada() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        var svc = new AgendaRoleBootstrapService(roleRepo, userRepo, "");

        Optional<UUID> result = svc.ensurePlatformAdminByEmail(OWNER_EMAIL);

        assertTrue(result.isEmpty());
        verify(userRepo, never()).findByEmail(any());
        verify(roleRepo, never()).save(any());
    }

    @Test
    void emailNoMatchea_noHaceNada() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        var svc = new AgendaRoleBootstrapService(roleRepo, userRepo, OWNER_EMAIL);

        Optional<UUID> result = svc.ensurePlatformAdminByEmail("otro@gmail.com");

        assertTrue(result.isEmpty());
        verify(userRepo, never()).findByEmail(any());
        verify(roleRepo, never()).save(any());
    }

    @Test
    void userNoExisteEnDB_omiteYDevuelveEmpty() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        when(userRepo.findByEmail(OWNER_EMAIL)).thenReturn(Optional.empty());
        var svc = new AgendaRoleBootstrapService(roleRepo, userRepo, OWNER_EMAIL);

        Optional<UUID> result = svc.ensurePlatformAdminByEmail(OWNER_EMAIL);

        assertTrue(result.isEmpty());
        verify(roleRepo, never()).save(any());
    }

    @Test
    void userExisteYNoTieneRolPA_loAsigna() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        UUID userId = UUID.randomUUID();
        when(userRepo.findByEmail(OWNER_EMAIL)).thenReturn(Optional.of(
                new User(userId, "t-1", "Jesus", OWNER_EMAIL, null,
                        UserType.ADMIN, true, null, null)));
        when(roleRepo.isPlatformAdmin(userId)).thenReturn(false);
        var svc = new AgendaRoleBootstrapService(roleRepo, userRepo, OWNER_EMAIL);

        Optional<UUID> result = svc.ensurePlatformAdminByEmail(OWNER_EMAIL);

        assertEquals(userId, result.orElseThrow());
        verify(roleRepo).save(any(AgendaUserRole.class));
    }

    @Test
    void userYaTienePA_esIdempotente() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        UUID userId = UUID.randomUUID();
        when(userRepo.findByEmail(OWNER_EMAIL)).thenReturn(Optional.of(
                new User(userId, "t-1", "Jesus", OWNER_EMAIL, null,
                        UserType.ADMIN, true, null, null)));
        when(roleRepo.isPlatformAdmin(userId)).thenReturn(true);
        var svc = new AgendaRoleBootstrapService(roleRepo, userRepo, OWNER_EMAIL);

        Optional<UUID> result = svc.ensurePlatformAdminByEmail(OWNER_EMAIL);

        assertEquals(userId, result.orElseThrow());
        verify(roleRepo, never()).save(any());
    }

    @Test
    void emailCaseInsensitive_normaliza() {
        var userRepo = mock(UserRepository.class);
        var roleRepo = mock(AgendaUserRoleRepository.class);
        UUID userId = UUID.randomUUID();
        when(userRepo.findByEmail(OWNER_EMAIL)).thenReturn(Optional.of(
                new User(userId, "t-1", "Jesus", OWNER_EMAIL, null,
                        UserType.ADMIN, true, null, null)));
        when(roleRepo.isPlatformAdmin(userId)).thenReturn(false);
        var svc = new AgendaRoleBootstrapService(
                roleRepo, userRepo, "  JesusHernandez1843@GMAIL.com  ");

        Optional<UUID> result = svc.ensurePlatformAdminByEmail("JESUSHERNANDEZ1843@gmail.com");

        assertFalse(result.isEmpty(), "Debe matchear ignorando case y trim");
        verify(roleRepo).save(any(AgendaUserRole.class));
    }
}

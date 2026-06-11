package com.botai.application.agenda.support;

import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgendaClientResolverTest {

    private static final String TENANT = "tenant-1";
    private static final String PHONE = "59897205089";
    private static final String EMAIL = "cliente@example.com";

    @Mock
    private UserRepository userRepository;

    @Test
    void resolveOrCreate_priorizaClienteDelTelefonoCuandoEmailPerteneceAOtro() {
        UUID phoneUserId = UUID.randomUUID();
        UUID emailUserId = UUID.randomUUID();
        User phoneUser = client(phoneUserId, "Cliente", null, PHONE);
        User emailUser = client(emailUserId, "Otro Nombre", EMAIL, null);

        when(userRepository.findClientByTenantIdAndTelefono(TENANT, PHONE))
                .thenReturn(Optional.of(phoneUser));
        when(userRepository.findByTenantIdAndEmail(TENANT, EMAIL))
                .thenReturn(Optional.of(emailUser));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        User result = AgendaClientResolver.resolveOrCreate(
                userRepository, TENANT, "María González", EMAIL, PHONE);

        assertEquals(phoneUserId, result.getId());
        assertEquals("María González", result.getNombre());
        assertEquals(EMAIL, result.getEmail());
        assertEquals(PHONE, result.getTelefono());

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(userRepository, times(2)).save(saved.capture());
        assertEquals(emailUserId, saved.getAllValues().get(0).getId());
        assertEquals(null, saved.getAllValues().get(0).getEmail());
        assertEquals(phoneUserId, saved.getAllValues().get(1).getId());
        assertEquals(EMAIL, saved.getAllValues().get(1).getEmail());
    }

    @Test
    void resolveOrCreate_asignaTelefonoAlClienteEncontradoPorEmailSiNoHayConflicto() {
        UUID emailUserId = UUID.randomUUID();
        User emailUser = client(emailUserId, "Ana", EMAIL, null);

        when(userRepository.findClientByTenantIdAndTelefono(TENANT, PHONE))
                .thenReturn(Optional.empty());
        when(userRepository.findByTenantIdAndEmail(TENANT, EMAIL))
                .thenReturn(Optional.of(emailUser));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        User result = AgendaClientResolver.resolveOrCreate(
                userRepository, TENANT, "Ana López", EMAIL, PHONE);

        assertEquals(emailUserId, result.getId());
        assertEquals("Ana López", result.getNombre());
        assertEquals(PHONE, result.getTelefono());
    }

    private static User client(UUID id, String nombre, String email, String telefono) {
        return new User(id, TENANT, nombre, email, telefono, UserType.CLIENT, true, null, null);
    }
}

package com.botai.application.agenda.security;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Resuelve {@link AgendaUserPrincipal} desde la base a partir del email del JWT.
 *
 * <p>Secuencia: email → {@code TenantAccount} (tenantId) → {@code User} (userId)
 * → roles efectivos. Si algún paso falla, devuelve un principal "anónimo" o
 * "sin roles" según corresponda — la decisión final de denegar acceso queda
 * en {@link AgendaAuthorizationService}.</p>
 */
@Service
public class AgendaPrincipalLoader {

    private final TenantAccountRepository tenantAccountRepository;
    private final UserRepository userRepository;
    private final AgendaUserRoleRepository roleRepository;

    public AgendaPrincipalLoader(TenantAccountRepository tenantAccountRepository,
                                  UserRepository userRepository,
                                  AgendaUserRoleRepository roleRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
    }

    public AgendaUserPrincipal loadByJwtEmail(String jwtEmail) {
        if (jwtEmail == null || jwtEmail.isBlank()) {
            return AgendaUserPrincipal.anonymous();
        }
        String email = jwtEmail.strip().toLowerCase(Locale.ROOT);

        // 1) Camino dueño: el email matchea un TenantAccount (alta original o
        //    Gmail vinculado vía /tenant-admin/link). El tenantId sale de ahí.
        Optional<String> tenantIdFromAccount = tenantAccountRepository.findByEmail(email)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(email))
                .map(a -> a.getTenantId());

        if (tenantIdFromAccount.isPresent()) {
            String tenantId = tenantIdFromAccount.get();
            Optional<User> user = userRepository.findByTenantIdAndEmail(tenantId, email);
            if (user.isEmpty()) {
                // Tenant resuelto pero sin User asociado: caso raro. Devolvemos sin roles.
                return new AgendaUserPrincipal(null, email, tenantId, List.of());
            }
            UUID userId = user.get().getId();
            List<AgendaUserRole> roles = roleRepository.findByUserId(userId);
            return new AgendaUserPrincipal(userId, email, tenantId, roles);
        }

        // 2) Camino miembro invitado: el email no es de ningún TenantAccount,
        //    pero existe un User con ese email (fue invitado por el dueño/TA).
        //    Resolvemos el tenant a partir del User.
        Optional<User> invitedUser = userRepository.findByEmail(email);
        if (invitedUser.isEmpty()) {
            return AgendaUserPrincipal.anonymous();
        }
        User u = invitedUser.get();
        List<AgendaUserRole> roles = roleRepository.findByUserId(u.getId());
        return new AgendaUserPrincipal(u.getId(), email, u.getTenantId(), roles);
    }
}

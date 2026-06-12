package com.botai.application.agenda.usecase.rbac;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Bootstrap idempotente del rol {@link Role#OWNER} de un tenant.
 *
 * <ul>
 *   <li>{@link #grantOwnerOnRegistration(UUID, String)} — alta inmediata cuando
 *       se registra un tenant nuevo (sin verificación previa: la transacción
 *       de registro recién creó el User).</li>
 *   <li>{@link #ensureOwnerByJwtEmail(String, String)} — auto-curado de tenants
 *       que existían antes de que existiera RBAC. Idempotente: si ya hay
 *       OWNER, no toca nada.</li>
 * </ul>
 */
@Service
public class AgendaRoleBootstrapService {

    private static final Logger log = LoggerFactory.getLogger(AgendaRoleBootstrapService.class);

    private final AgendaUserRoleRepository roleRepository;
    private final UserRepository userRepository;

    public AgendaRoleBootstrapService(AgendaUserRoleRepository roleRepository,
                                       UserRepository userRepository) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public void grantOwnerOnRegistration(UUID userId, String tenantId) {
        roleRepository.save(AgendaUserRole.tenantWide(userId, tenantId, Role.OWNER));
        log.info("RBAC: OWNER asignado tenantId={} userId={} (registro nuevo)", tenantId, userId);
    }

    /**
     * Si el tenant aún no tiene OWNER, busca el {@link User} por email dentro
     * del tenant y le otorga el rol. Pensado para tenants creados antes de
     * RBAC: la primera llamada autenticada (típicamente {@code GET
     * /api/agenda/me/tenant-admin}) dispara el bootstrap.
     *
     * @return userId del OWNER (existente o recién bootstrapeado), si pudo determinarse.
     */
    @Transactional
    public Optional<UUID> ensureOwnerByJwtEmail(String jwtEmail, String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return Optional.empty();
        }
        if (roleRepository.existsOwnerByTenantId(tenantId)) {
            return roleRepository.findOwnerByTenantId(tenantId).map(AgendaUserRole::getUserId);
        }
        if (jwtEmail == null || jwtEmail.isBlank()) {
            return Optional.empty();
        }
        String normalizedEmail = jwtEmail.strip().toLowerCase(Locale.ROOT);
        Optional<User> user = userRepository.findByTenantIdAndEmail(tenantId, normalizedEmail);
        if (user.isEmpty()) {
            log.debug("RBAC: bootstrap OWNER omitido para tenantId={} — no existe User con email={}",
                    tenantId, normalizedEmail);
            return Optional.empty();
        }
        UUID userId = user.get().getId();
        roleRepository.save(AgendaUserRole.tenantWide(userId, tenantId, Role.OWNER));
        log.info("RBAC: OWNER bootstrap tenantId={} userId={} (tenant pre-RBAC)", tenantId, userId);
        return Optional.of(userId);
    }
}

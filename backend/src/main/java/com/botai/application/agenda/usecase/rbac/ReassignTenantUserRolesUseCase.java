package com.botai.application.agenda.usecase.rbac;

import com.botai.application.agenda.dto.ReassignTenantUserRolesRequest;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

/**
 * Reemplaza todas las asignaciones de rol de un {@link User} dentro del tenant
 * actual. OWNER only — pensado para "promover/degradar" a un miembro existente.
 *
 * <p>Si después de la reasignación el usuario queda sin rol alguno en el
 * tenant, queda funcionalmente "bloqueado" (no podrá operar nada). El
 * {@link RevokeTenantUserUseCase} cubre la baja completa.</p>
 */
@Service
public class ReassignTenantUserRolesUseCase {

    private static final Logger log = LoggerFactory.getLogger(ReassignTenantUserRolesUseCase.class);

    private final UserRepository userRepository;
    private final AgendaUserRoleRepository roleRepository;
    private final BusinessRepository businessRepository;

    public ReassignTenantUserRolesUseCase(UserRepository userRepository,
                                           AgendaUserRoleRepository roleRepository,
                                           BusinessRepository businessRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional
    public List<AgendaUserRole> execute(String tenantId,
                                        UUID targetUserId,
                                        ReassignTenantUserRolesRequest req) {
        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new NoSuchElementException("User no encontrado: " + targetUserId));
        if (!user.getTenantId().equals(tenantId)) {
            throw new NoSuchElementException("User no encontrado: " + targetUserId);
        }

        // 1) Validar businesses de cada asignación contra el tenant.
        for (var spec : req.assignments()) {
            Role role = Role.valueOf(spec.role());
            if (role.isBusinessScope()) {
                if (spec.businessIds() == null || spec.businessIds().isEmpty()) {
                    throw new IllegalArgumentException(
                            "Rol " + role + " requiere al menos una sucursal.");
                }
                for (UUID businessId : spec.businessIds()) {
                    businessRepository.findByIdAndTenantId(businessId, tenantId)
                            .orElseThrow(() -> new BusinessNotFoundException(businessId));
                }
            }
        }

        // 2) Borrar todas las asignaciones actuales del usuario en este tenant.
        List<AgendaUserRole> current = roleRepository.findByUserIdAndTenantId(targetUserId, tenantId);
        for (AgendaUserRole r : current) {
            // Protección: no eliminar OWNER por este endpoint — la transferencia
            // de propiedad es un flujo aparte.
            if (r.getRole() == Role.OWNER) {
                throw new IllegalStateException(
                        "No se puede reasignar el rol OWNER por este endpoint.");
            }
            roleRepository.delete(r.getId());
        }

        // 3) Insertar las nuevas.
        for (var spec : req.assignments()) {
            Role role = Role.valueOf(spec.role());
            if (role == Role.TENANT_ADMIN) {
                roleRepository.save(AgendaUserRole.tenantWide(targetUserId, tenantId, role));
            } else if (role.isBusinessScope()) {
                for (UUID businessId : spec.businessIds()) {
                    roleRepository.save(AgendaUserRole.forBusiness(targetUserId, tenantId, businessId, role));
                }
            }
        }

        List<AgendaUserRole> result = roleRepository.findByUserIdAndTenantId(targetUserId, tenantId);
        log.info("RBAC: reasignación userId={} tenant={} nuevasAsignaciones={}",
                targetUserId, tenantId, result.size());
        return result;
    }
}

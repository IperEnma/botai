package com.botai.application.agenda.usecase.rbac;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

/**
 * Revoca todo acceso de un {@link User} al tenant actual:
 * <ul>
 *   <li>Borra todas sus {@link AgendaUserRole} en este tenant.</li>
 *   <li>Si tenía un {@link StaffMember} linkeado, lo desvincula
 *       ({@code userId = null}) — el perfil queda como "STAFF sin cuenta".</li>
 *   <li>No borra el {@link User} ni la fila del StaffMember: si se reinvita
 *       después, conservamos el id.</li>
 * </ul>
 *
 * <p>OWNER only.</p>
 */
@Service
public class RevokeTenantUserUseCase {

    private static final Logger log = LoggerFactory.getLogger(RevokeTenantUserUseCase.class);

    private final UserRepository userRepository;
    private final AgendaUserRoleRepository roleRepository;
    private final StaffMemberRepository staffMemberRepository;

    public RevokeTenantUserUseCase(UserRepository userRepository,
                                    AgendaUserRoleRepository roleRepository,
                                    StaffMemberRepository staffMemberRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.staffMemberRepository = staffMemberRepository;
    }

    @Transactional
    public void execute(String tenantId, UUID targetUserId) {
        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new NoSuchElementException("User no encontrado: " + targetUserId));
        if (!user.getTenantId().equals(tenantId)) {
            throw new NoSuchElementException("User no encontrado: " + targetUserId);
        }

        // Protegemos al OWNER del tenant: este flujo no puede tumbar al dueño.
        List<AgendaUserRole> current = roleRepository.findByUserIdAndTenantId(targetUserId, tenantId);
        for (AgendaUserRole r : current) {
            if (r.getRole() == Role.OWNER) {
                throw new IllegalStateException(
                        "No se puede revocar el OWNER del tenant por este endpoint.");
            }
        }

        // 1) Borrar todas las asignaciones de rol del usuario en este tenant.
        for (AgendaUserRole r : current) {
            roleRepository.delete(r.getId());
        }

        // 2) Desvincular StaffMember si existía.
        //    Iteramos los staff de cada sucursal del tenant donde el user
        //    pudiera estar linkeado. (Esto es ineficiente si hay miles de staff
        //    en el tenant; en MVP es aceptable porque el user típicamente
        //    pertenece a 1-3 sucursales como mucho.)
        // Iteración por las asignaciones que tenía, no por todos los staff:
        for (AgendaUserRole r : current) {
            if (r.getBusinessId() == null) continue;
            List<StaffMember> staff = staffMemberRepository.findByBusinessId(r.getBusinessId());
            for (StaffMember sm : staff) {
                if (targetUserId.equals(sm.getUserId())) {
                    StaffMember unlinked = StaffMember.builder()
                            .id(sm.getId())
                            .userId(null)
                            .businessIds(sm.getBusinessIds())
                            .nombre(sm.getNombre())
                            .rol(sm.getRol())
                            .avatarUrl(sm.getAvatarUrl())
                            .telefono(sm.getTelefono())
                            .email(sm.getEmail())
                            .bio(sm.getBio())
                            .color(sm.getColor())
                            .status(sm.getStatus())
                            .customSchedule(sm.getCustomSchedule())
                            .serviceIds(sm.getServiceIds())
                            .deletedAt(sm.getDeletedAt())
                            .createdAt(sm.getCreatedAt())
                            .updatedAt(sm.getUpdatedAt())
                            .build();
                    staffMemberRepository.save(unlinked);
                }
            }
        }

        log.info("RBAC: revocación userId={} tenant={} rolesEliminados={}",
                targetUserId, tenantId, current.size());
    }
}

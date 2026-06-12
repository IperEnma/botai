package com.botai.application.agenda.usecase.rbac;

import com.botai.application.agenda.dto.CreateTenantInvitationRequest;
import com.botai.application.agenda.dto.TenantInvitationResponse;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.AgendaUserRoleRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Alta de un miembro del tenant con rol RBAC.
 *
 * <p>Único punto de entrada para "invitar" a alguien: crea (o reutiliza) un
 * {@link User} con el email del invitado, asigna las {@link AgendaUserRole}
 * pedidas, y para roles {@code STAFF_*} crea además el {@link StaffMember}
 * vinculado.</p>
 *
 * <p>El control de quién puede invitar a cada rol vive en el controller vía
 * {@code @PreAuthorize("@authz.canInviteRole(...)")}. Acá asumimos que el
 * caller ya pasó esa autorización.</p>
 */
@Service
public class InviteTenantUserUseCase {

    private static final Logger log = LoggerFactory.getLogger(InviteTenantUserUseCase.class);

    private final UserRepository userRepository;
    private final AgendaUserRoleRepository roleRepository;
    private final StaffMemberRepository staffMemberRepository;
    private final BusinessRepository businessRepository;
    private final StaffInvitationEmailService invitationEmail;

    public InviteTenantUserUseCase(UserRepository userRepository,
                                    AgendaUserRoleRepository roleRepository,
                                    StaffMemberRepository staffMemberRepository,
                                    BusinessRepository businessRepository,
                                    StaffInvitationEmailService invitationEmail) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.businessRepository = businessRepository;
        this.invitationEmail = invitationEmail;
    }

    @Transactional
    public TenantInvitationResponse execute(String tenantId, CreateTenantInvitationRequest req) {
        Role role = Role.valueOf(req.role());
        String email = req.email().strip().toLowerCase(Locale.ROOT);
        String nombre = req.nombre().trim();
        String telefonoNorm = AgendaPhoneNormalizer.normalizeOrNull(req.telefono());
        List<UUID> businessIds = role.isBusinessScope() ? req.businessIds() : List.of();

        // 1) Validar que cada sucursal pertenezca al tenant actual y capturar nombres
        //    para el mail de invitación.
        List<String> businessNames = new ArrayList<>();
        for (UUID businessId : businessIds) {
            Business biz = businessRepository.findByIdAndTenantId(businessId, tenantId)
                    .orElseThrow(() -> new BusinessNotFoundException(businessId));
            businessNames.add(biz.getNombre());
        }

        // 2) Resolver el User: si el email ya tiene cuenta en otro tenant,
        //    rechazar — un email = un tenant en esta iteración.
        Optional<User> existing = userRepository.findByEmail(email);
        User user;
        boolean userExisted;
        if (existing.isPresent()) {
            User u = existing.get();
            if (!u.getTenantId().equals(tenantId)) {
                throw new IllegalStateException(
                        "El email " + email + " ya está registrado en otro tenant.");
            }
            user = u;
            userExisted = true;
        } else {
            user = userRepository.save(new User(
                    UUID.randomUUID(),
                    tenantId,
                    nombre,
                    email,
                    telefonoNorm,
                    UserType.ADMIN, // miembro del tenant — no aparece en CRM de clientes
                    true,
                    null,
                    null
            ));
            userExisted = false;
        }
        UUID userId = user.getId();

        // 3) Asignar roles (idempotente: skip si ya existe).
        if (role == Role.TENANT_ADMIN) {
            if (!roleRepository.exists(userId, tenantId, null, role)) {
                roleRepository.save(AgendaUserRole.tenantWide(userId, tenantId, role));
            }
        } else if (role.isBusinessScope()) {
            for (UUID businessId : businessIds) {
                if (!roleRepository.exists(userId, tenantId, businessId, role)) {
                    roleRepository.save(AgendaUserRole.forBusiness(userId, tenantId, businessId, role));
                }
            }
        }

        // 4) Para roles STAFF_*, crear (o reutilizar) un StaffMember linkeado.
        UUID staffMemberId = null;
        if (role == Role.STAFF_OPERATOR || role == Role.STAFF_VIEWER) {
            StaffMember sm = StaffMember.builder()
                    .id(UUID.randomUUID())
                    .userId(userId)
                    .businessIds(new LinkedHashSet<>(businessIds))
                    .nombre(nombre)
                    .telefono(telefonoNorm)
                    .email(email)
                    .status("ACTIVO")
                    .build();
            StaffMember saved = staffMemberRepository.save(sm);
            staffMemberId = saved.getId();
        }

        log.info("RBAC: invitación userId={} email={} role={} tenant={} businesses={} userExisted={}",
                userId, email, role, tenantId, businessIds, userExisted);

        // 5) Notificar por mail (best-effort: si falla solo se loguea).
        invitationEmail.sendForInvitation(nombre, email, role, businessNames);

        return new TenantInvitationResponse(
                userId, email, nombre, role.name(), businessIds, staffMemberId, userExisted);
    }
}

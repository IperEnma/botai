package com.botai.application.agenda.security;

import com.botai.domain.agenda.model.AgendaUserRole;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AgendaAuthorizationServiceTest {

    private static final String TENANT_ID = "tenant-1";
    private static final UUID USER_ID = UUID.randomUUID();
    private static final UUID BUSINESS_ID = UUID.randomUUID();
    private static final UUID OTHER_BUSINESS_ID = UUID.randomUUID();

    private BusinessRepository businessRepository;
    private StaffMemberRepository staffMemberRepository;

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        staffMemberRepository = mock(StaffMemberRepository.class);
        when(businessRepository.findByIdAndTenantId(eq(BUSINESS_ID), eq(TENANT_ID)))
                .thenReturn(Optional.of(mock(Business.class)));
        when(businessRepository.findByIdAndTenantId(eq(OTHER_BUSINESS_ID), any()))
                .thenReturn(Optional.empty());
    }

    private AgendaAuthorizationService authzWith(AgendaUserPrincipal principal) {
        return new AgendaAuthorizationService(
                () -> principal, businessRepository, staffMemberRepository);
    }

    private StaffMember staffMemberWithId(UUID staffId) {
        return StaffMember.builder()
                .id(staffId)
                .userId(USER_ID)
                .businessIds(new LinkedHashSet<>(List.of(BUSINESS_ID)))
                .nombre("Pedro")
                .status("ACTIVO")
                .build();
    }

    private AgendaUserPrincipal principalWith(Role role, UUID businessId) {
        AgendaUserRole assignment = businessId == null
                ? AgendaUserRole.tenantWide(USER_ID, TENANT_ID, role)
                : AgendaUserRole.forBusiness(USER_ID, TENANT_ID, businessId, role);
        return new AgendaUserPrincipal(USER_ID, "u@example.com", TENANT_ID, List.of(assignment));
    }

    // ─── Anonymous ─────────────────────────────────────────────────────────

    @Test
    void anonymous_noPuedeNada() {
        var auth = authzWith(AgendaUserPrincipal.anonymous());
        assertFalse(auth.isOwner());
        assertFalse(auth.isTenantAdmin());
        assertFalse(auth.isPlatformAdmin());
        assertFalse(auth.canManageBusiness(BUSINESS_ID));
        assertFalse(auth.canManageAgenda(BUSINESS_ID));
        assertFalse(auth.canViewAgenda(BUSINESS_ID));
    }

    // ─── OWNER ─────────────────────────────────────────────────────────────

    @Test
    void owner_puede_gestionarTodoElTenant() {
        var auth = authzWith(principalWith(Role.OWNER, null));
        assertTrue(auth.isOwner());
        assertTrue(auth.isTenantAdmin());
        assertTrue(auth.canManageTenant());
        assertTrue(auth.canManageBusiness(BUSINESS_ID));
        assertTrue(auth.canManageBusinessOwnerOnly(BUSINESS_ID));
        assertTrue(auth.canManageAgenda(BUSINESS_ID));
        assertTrue(auth.canViewAgenda(BUSINESS_ID));
        assertTrue(auth.canManageClientsCrm(BUSINESS_ID));
    }

    @Test
    void owner_noPuede_operarBusinessDeOtroTenant() {
        var auth = authzWith(principalWith(Role.OWNER, null));
        assertFalse(auth.canManageBusiness(OTHER_BUSINESS_ID));
        assertFalse(auth.canManageAgenda(OTHER_BUSINESS_ID));
    }

    // ─── TENANT_ADMIN ──────────────────────────────────────────────────────

    @Test
    void tenantAdmin_administraPeroNoTransfiereNiBorra() {
        var auth = authzWith(principalWith(Role.TENANT_ADMIN, null));
        assertFalse(auth.isOwner());
        assertTrue(auth.isTenantAdmin());
        assertFalse(auth.canManageTenant());
        assertTrue(auth.canManageBusiness(BUSINESS_ID));
        assertFalse(auth.canManageBusinessOwnerOnly(BUSINESS_ID));
        assertTrue(auth.canManageAgenda(BUSINESS_ID));
    }

    // ─── RECEPTION ─────────────────────────────────────────────────────────

    @Test
    void reception_soloOperaEnSucursalesAsignadas() {
        var auth = authzWith(principalWith(Role.RECEPTION, BUSINESS_ID));
        assertFalse(auth.isOwner());
        assertFalse(auth.isTenantAdmin());
        assertTrue(auth.canManageAgenda(BUSINESS_ID));
        assertTrue(auth.canViewAgenda(BUSINESS_ID));
        assertTrue(auth.canManageClientsCrm(BUSINESS_ID));
        // No configura nada
        assertFalse(auth.canManageBusiness(BUSINESS_ID));
    }

    @Test
    void reception_puedeCrearBookingParaCualquierStaff() {
        var auth = authzWith(principalWith(Role.RECEPTION, BUSINESS_ID));
        // No matchea su propio staffMember (RC no es staff). Pasa igual porque
        // canManageBookingFor permite a RC sobre cualquier profesional.
        assertTrue(auth.canManageBookingFor(BUSINESS_ID, UUID.randomUUID()),
                "RECEPTION debe poder asignar reservas a cualquier staff");
    }

    @Test
    void reception_gestionaOperaciones_servicios_equipo_horarios_pero_no_settings() {
        var auth = authzWith(principalWith(Role.RECEPTION, BUSINESS_ID));
        // Operaciones del día a día sobre su sucursal: SÍ.
        assertTrue(auth.canManageBusinessOperations(BUSINESS_ID),
                "RC opera servicios/equipo/horarios de su sucursal");
        assertTrue(auth.canManageOwnStaffSchedule(BUSINESS_ID, UUID.randomUUID()),
                "RC edita el horario de cualquier staff de su sucursal");
        // Pero NO settings, branding, fotos, planes, features, bot, admins.
        assertFalse(auth.canManageBusiness(BUSINESS_ID),
                "RC no toca settings / branding / fotos / planes");
        assertFalse(auth.canManageBusinessOwnerOnly(BUSINESS_ID));
        assertFalse(auth.canManageTenant());
        // Invitaciones: solo STAFF_* — no se autoreplica ni crea admins.
        assertTrue(auth.canInviteRole("STAFF_OPERATOR"),
                "RC suma profesionales a su equipo");
        assertTrue(auth.canInviteRole("STAFF_VIEWER"));
        assertFalse(auth.canInviteRole("RECEPTION"),
                "RC no se autoreplica");
        assertFalse(auth.canInviteRole("TENANT_ADMIN"));
    }

    @Test
    void reception_noPuede_operarEnSucursalNoAsignada_operaciones() {
        var auth = authzWith(principalWith(Role.RECEPTION, BUSINESS_ID));
        UUID otherBizSameTenant = UUID.randomUUID();
        when(businessRepository.findByIdAndTenantId(eq(otherBizSameTenant), eq(TENANT_ID)))
                .thenReturn(Optional.of(mock(Business.class)));
        assertFalse(auth.canManageBusinessOperations(otherBizSameTenant),
                "RC no opera sucursales donde no tiene rol asignado");
        assertFalse(auth.canManageOwnStaffSchedule(otherBizSameTenant, UUID.randomUUID()));
    }

    @Test
    void reception_noPuede_operarEnSucursalNoAsignada() {
        var auth = authzWith(principalWith(Role.RECEPTION, BUSINESS_ID));
        // Otro business pero del mismo tenant
        UUID otherBizSameTenant = UUID.randomUUID();
        when(businessRepository.findByIdAndTenantId(eq(otherBizSameTenant), eq(TENANT_ID)))
                .thenReturn(Optional.of(mock(Business.class)));
        assertFalse(auth.canManageAgenda(otherBizSameTenant));
        assertFalse(auth.canViewAgenda(otherBizSameTenant));
    }

    // ─── STAFF_VIEWER ──────────────────────────────────────────────────────

    @Test
    void staffViewer_soloVeAgenda_noModifica() {
        var auth = authzWith(principalWith(Role.STAFF_VIEWER, BUSINESS_ID));
        assertTrue(auth.canViewAgenda(BUSINESS_ID));
        assertFalse(auth.canManageAgenda(BUSINESS_ID));
        assertFalse(auth.canManageBookingFor(BUSINESS_ID, UUID.randomUUID()));
        assertFalse(auth.canManageClientsCrm(BUSINESS_ID));
        assertFalse(auth.canManageBusiness(BUSINESS_ID));
    }

    // ─── STAFF_OPERATOR ────────────────────────────────────────────────────

    @Test
    void staffOperator_puedeModificarBookingPropio() {
        UUID ownStaffId = UUID.randomUUID();
        when(staffMemberRepository.findByUserIdAndBusinessId(USER_ID, BUSINESS_ID))
                .thenReturn(Optional.of(staffMemberWithId(ownStaffId)));

        var auth = authzWith(principalWith(Role.STAFF_OPERATOR, BUSINESS_ID));
        assertTrue(auth.canViewAgenda(BUSINESS_ID));
        assertTrue(auth.canManageBookingFor(BUSINESS_ID, ownStaffId));
        assertFalse(auth.canManageBookingFor(BUSINESS_ID, null));
        assertTrue(auth.canManageClientsCrm(BUSINESS_ID));
    }

    @Test
    void staffOperator_noPuedeModificarBookingDeOtroProfesional() {
        UUID ownStaffId = UUID.randomUUID();
        UUID otherStaffId = UUID.randomUUID();
        when(staffMemberRepository.findByUserIdAndBusinessId(USER_ID, BUSINESS_ID))
                .thenReturn(Optional.of(staffMemberWithId(ownStaffId)));

        var auth = authzWith(principalWith(Role.STAFF_OPERATOR, BUSINESS_ID));
        assertFalse(auth.canManageBookingFor(BUSINESS_ID, otherStaffId),
                "STAFF_OPERATOR no debe poder asignar reservas a otro staff");
    }

    @Test
    void staffOperator_puedeEditarSuPropioHorario() {
        UUID ownStaffId = UUID.randomUUID();
        when(staffMemberRepository.findByUserIdAndBusinessId(USER_ID, BUSINESS_ID))
                .thenReturn(Optional.of(staffMemberWithId(ownStaffId)));

        var auth = authzWith(principalWith(Role.STAFF_OPERATOR, BUSINESS_ID));
        assertTrue(auth.canManageOwnStaffSchedule(BUSINESS_ID, ownStaffId));
        assertFalse(auth.canManageOwnStaffSchedule(BUSINESS_ID, UUID.randomUUID()),
                "STAFF no debe poder editar el horario de otro staff");
    }

    @Test
    void staffViewer_noPuedeEditarSuHorario() {
        UUID ownStaffId = UUID.randomUUID();
        when(staffMemberRepository.findByUserIdAndBusinessId(USER_ID, BUSINESS_ID))
                .thenReturn(Optional.of(staffMemberWithId(ownStaffId)));

        var auth = authzWith(principalWith(Role.STAFF_VIEWER, BUSINESS_ID));
        assertFalse(auth.canManageOwnStaffSchedule(BUSINESS_ID, ownStaffId),
                "STAFF_VIEWER es solo lectura — no edita su horario");
    }

    @Test
    void owner_puedeEditarHorarioDeCualquierStaff() {
        var auth = authzWith(principalWith(Role.OWNER, null));
        // No hace falta mockear staffMemberRepository — OW pasa por isAdministrative.
        assertTrue(auth.canManageOwnStaffSchedule(BUSINESS_ID, UUID.randomUUID()));
    }

    @Test
    void staffOperator_sinPerfilDeStaffEnLaSucursal_noPuedeOperar() {
        when(staffMemberRepository.findByUserIdAndBusinessId(USER_ID, BUSINESS_ID))
                .thenReturn(Optional.empty());

        var auth = authzWith(principalWith(Role.STAFF_OPERATOR, BUSINESS_ID));
        // Tiene el rol RBAC pero sin StaffMember vinculado en esa sucursal:
        // no hay forma de saber "su propio booking", así que se niega.
        assertFalse(auth.canManageBookingFor(BUSINESS_ID, UUID.randomUUID()));
    }

    // ─── PLATFORM_ADMIN ────────────────────────────────────────────────────

    @Test
    void platformAdmin_veCualquierBusiness() {
        AgendaUserRole pa = AgendaUserRole.platform(USER_ID);
        var principal = new AgendaUserPrincipal(USER_ID, "pa@example.com", null, List.of(pa));
        var auth = authzWith(principal);
        assertTrue(auth.isPlatformAdmin());
        // Puede ver business aunque no haya tenant resuelto.
        assertTrue(auth.canViewBusiness(BUSINESS_ID));
        // No tiene rol administrativo de tenant.
        assertFalse(auth.isTenantAdmin());
        assertFalse(auth.canManageBusiness(BUSINESS_ID));
    }

    // ─── Ownership ─────────────────────────────────────────────────────────

    @Test
    void isCurrentUser_matchExacto() {
        var auth = authzWith(principalWith(Role.OWNER, null));
        assertTrue(auth.isCurrentUser(USER_ID));
        assertFalse(auth.isCurrentUser(UUID.randomUUID()));
        assertFalse(auth.isCurrentUser(null));
    }
}

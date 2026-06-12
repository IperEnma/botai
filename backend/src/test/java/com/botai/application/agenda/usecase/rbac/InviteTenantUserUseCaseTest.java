package com.botai.application.agenda.usecase.rbac;

import com.botai.application.agenda.dto.CreateTenantInvitationRequest;
import com.botai.application.agenda.dto.TenantInvitationResponse;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class InviteTenantUserUseCaseTest {

    private static final String TENANT = "t-1";
    private static final UUID BIZ = UUID.randomUUID();

    private UserRepository userRepo;
    private AgendaUserRoleRepository roleRepo;
    private StaffMemberRepository staffRepo;
    private BusinessRepository businessRepo;
    private StaffInvitationEmailService invitationEmail;
    private InviteTenantUserUseCase useCase;

    @BeforeEach
    void setUp() {
        userRepo = mock(UserRepository.class);
        roleRepo = mock(AgendaUserRoleRepository.class);
        staffRepo = mock(StaffMemberRepository.class);
        businessRepo = mock(BusinessRepository.class);
        invitationEmail = mock(StaffInvitationEmailService.class);
        useCase = new InviteTenantUserUseCase(userRepo, roleRepo, staffRepo, businessRepo, invitationEmail);

        Business biz = mock(Business.class);
        when(biz.getNombre()).thenReturn("Estudio Norte");
        when(businessRepo.findByIdAndTenantId(eq(BIZ), eq(TENANT)))
                .thenReturn(Optional.of(biz));
        when(userRepo.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        when(roleRepo.save(any(AgendaUserRole.class))).thenAnswer(inv -> inv.getArgument(0));
        when(staffRepo.save(any(StaffMember.class))).thenAnswer(inv -> inv.getArgument(0));
        when(roleRepo.exists(any(), anyString(), any(), any())).thenReturn(false);
    }

    private CreateTenantInvitationRequest req(String role, List<UUID> businesses) {
        return new CreateTenantInvitationRequest(
                "Juan Perez", "juan@example.com", "+598099111222", role, businesses);
    }

    @Test
    void inviteStaffOperator_creaUserRoleYStaffMember() {
        when(userRepo.findByEmail("juan@example.com")).thenReturn(Optional.empty());

        TenantInvitationResponse response = useCase.execute(TENANT, req("STAFF_OPERATOR", List.of(BIZ)));

        verify(userRepo).save(any(User.class));
        verify(roleRepo).save(any(AgendaUserRole.class));
        verify(staffRepo).save(any(StaffMember.class));
        verify(invitationEmail).sendForInvitation(
                eq("Juan Perez"), eq("juan@example.com"),
                eq(Role.STAFF_OPERATOR), eq(List.of("Estudio Norte")));

        assertFalse(response.userExisted());
        assertNotNull(response.staffMemberId(), "STAFF_* debe generar StaffMember");
        assertEquals("STAFF_OPERATOR", response.role());
        assertEquals(List.of(BIZ), response.businessIds());
    }

    @Test
    void inviteReception_creaUserRolePeroNoStaffMember() {
        when(userRepo.findByEmail("juan@example.com")).thenReturn(Optional.empty());

        TenantInvitationResponse response = useCase.execute(TENANT, req("RECEPTION", List.of(BIZ)));

        verify(userRepo).save(any(User.class));
        verify(roleRepo).save(any(AgendaUserRole.class));
        verify(staffRepo, never()).save(any(StaffMember.class));

        assertNull(response.staffMemberId(), "RECEPTION no genera StaffMember");
    }

    @Test
    void inviteTenantAdmin_ignoraBusinessIds_creaRolTenantWide() {
        when(userRepo.findByEmail(anyString())).thenReturn(Optional.empty());

        useCase.execute(TENANT, req("TENANT_ADMIN", List.of()));

        ArgumentCaptor<AgendaUserRole> roleCaptor = ArgumentCaptor.forClass(AgendaUserRole.class);
        verify(roleRepo).save(roleCaptor.capture());
        AgendaUserRole saved = roleCaptor.getValue();
        assertEquals(Role.TENANT_ADMIN, saved.getRole());
        assertNull(saved.getBusinessId(), "TENANT_ADMIN es tenant-wide → businessId null");
        verify(staffRepo, never()).save(any());
        verify(invitationEmail).sendForInvitation(
                eq("Juan Perez"), eq("juan@example.com"),
                eq(Role.TENANT_ADMIN), eq(List.of()));
    }

    @Test
    void inviteUserExistente_reusaIdNoCreaUser() {
        UUID existingId = UUID.randomUUID();
        User existing = new User(existingId, TENANT, "Juan Perez", "juan@example.com",
                null, UserType.ADMIN, true, null, null);
        when(userRepo.findByEmail("juan@example.com")).thenReturn(Optional.of(existing));

        TenantInvitationResponse response = useCase.execute(TENANT, req("RECEPTION", List.of(BIZ)));

        verify(userRepo, never()).save(any(User.class));
        verify(roleRepo).save(any(AgendaUserRole.class));
        assertTrue(response.userExisted());
        assertEquals(existingId, response.userId());
    }

    @Test
    void inviteEmailDeOtroTenant_lanza() {
        User otroTenantUser = new User(UUID.randomUUID(), "otro-tenant", "Juan Perez",
                "juan@example.com", null, UserType.ADMIN, true, null, null);
        when(userRepo.findByEmail("juan@example.com")).thenReturn(Optional.of(otroTenantUser));

        assertThrows(IllegalStateException.class, () ->
                useCase.execute(TENANT, req("STAFF_OPERATOR", List.of(BIZ))));
    }

    @Test
    void inviteBusinessNoPerteneceAlTenant_lanza() {
        UUID businessAjeno = UUID.randomUUID();
        when(businessRepo.findByIdAndTenantId(eq(businessAjeno), eq(TENANT)))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class, () ->
                useCase.execute(TENANT, req("STAFF_OPERATOR", List.of(businessAjeno))));
    }

    @Test
    void roleYaAsignado_noDuplica() {
        when(userRepo.findByEmail(anyString())).thenReturn(Optional.empty());
        when(roleRepo.exists(any(), eq(TENANT), eq(BIZ), eq(Role.RECEPTION))).thenReturn(true);

        useCase.execute(TENANT, req("RECEPTION", List.of(BIZ)));

        // El use case verificó pero NO guardó el rol duplicado.
        verify(roleRepo, never()).save(any(AgendaUserRole.class));
    }
}

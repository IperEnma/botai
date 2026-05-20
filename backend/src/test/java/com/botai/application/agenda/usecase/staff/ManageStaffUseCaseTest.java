package com.botai.application.agenda.usecase.staff;

import com.botai.application.agenda.dto.CreateStaffMemberRequest;
import com.botai.application.agenda.dto.UpdateStaffMemberRequest;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.StaffMemberNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests de {@link ManageStaffUseCase}. Sin Spring.
 */
class ManageStaffUseCaseTest {

    private BusinessRepository businessRepository;
    private StaffMemberRepository staffMemberRepository;
    private ManageStaffUseCase useCase;

    private final String TENANT = "tenant-1";
    private final UUID BUSINESS_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        businessRepository = mock(BusinessRepository.class);
        staffMemberRepository = mock(StaffMemberRepository.class);
        useCase = new ManageStaffUseCase(businessRepository, staffMemberRepository);

        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.of(business()));
    }

    // ── list ────────────────────────────────────────────────────────────────

    @Test
    void list_devuelveListaDeStaffDelNegocio() {
        List<StaffMember> members = List.of(staffMember(BUSINESS_ID), staffMember(BUSINESS_ID));
        when(staffMemberRepository.findByBusinessId(BUSINESS_ID)).thenReturn(members);

        List<StaffMember> result = useCase.list(TENANT, BUSINESS_ID);

        assertEquals(2, result.size());
        verify(staffMemberRepository).findByBusinessId(BUSINESS_ID);
    }

    @Test
    void list_lanzaBusinessNotFound_siTenantNoCoincide() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        assertThrows(BusinessNotFoundException.class,
                () -> useCase.list(TENANT, BUSINESS_ID));

        verify(staffMemberRepository, never()).findByBusinessId(any());
    }

    // ── create ───────────────────────────────────────────────────────────────

    @Test
    void create_guardaStaffMemberConCamposCorrectos() {
        var req = new CreateStaffMemberRequest("Juan Perez", "Estilista", null, null);
        StaffMember saved = staffMember(BUSINESS_ID);
        when(staffMemberRepository.save(any())).thenReturn(saved);

        StaffMember result = useCase.create(TENANT, BUSINESS_ID, req);

        assertNotNull(result);
        verify(staffMemberRepository).save(any(StaffMember.class));
    }

    @Test
    void create_lanzaBusinessNotFound_siNegocioNoExiste() {
        when(businessRepository.findByIdAndTenantId(BUSINESS_ID, TENANT))
                .thenReturn(Optional.empty());

        var req = new CreateStaffMemberRequest("Juan", null, null, null);
        assertThrows(BusinessNotFoundException.class,
                () -> useCase.create(TENANT, BUSINESS_ID, req));
    }

    // ── update ───────────────────────────────────────────────────────────────

    @Test
    void update_actualizaCamposCorrectos() {
        UUID staffId = UUID.randomUUID();
        StaffMember existing = staffMemberWithId(staffId, BUSINESS_ID);
        when(staffMemberRepository.findById(staffId)).thenReturn(Optional.of(existing));

        StaffMember updatedSaved = new StaffMember(staffId, BUSINESS_ID,
                "Nuevo Nombre", "Nuevo Rol", null, null, null, null, null, "ACTIVO", null, null, null, null, null);
        when(staffMemberRepository.save(any())).thenReturn(updatedSaved);

        var req = new UpdateStaffMemberRequest("Nuevo Nombre", "Nuevo Rol", null, null, null, null, null, "ACTIVO", null);
        StaffMember result = useCase.update(TENANT, BUSINESS_ID, staffId, req);

        assertEquals("Nuevo Nombre", result.getNombre());
        verify(staffMemberRepository).save(any(StaffMember.class));
    }

    @Test
    void update_lanzaStaffNotFound_siNoExiste() {
        UUID staffId = UUID.randomUUID();
        when(staffMemberRepository.findById(staffId)).thenReturn(Optional.empty());

        var req = new UpdateStaffMemberRequest("Nombre", null, null, null, null, null, null, "ACTIVO", null);
        assertThrows(StaffMemberNotFoundException.class,
                () -> useCase.update(TENANT, BUSINESS_ID, staffId, req));
    }

    @Test
    void update_lanzaStaffNotFound_siPerteneceAOtroNegocio() {
        UUID staffId = UUID.randomUUID();
        UUID otroNegocio = UUID.randomUUID();
        StaffMember staffDeOtro = staffMemberWithId(staffId, otroNegocio);
        when(staffMemberRepository.findById(staffId)).thenReturn(Optional.of(staffDeOtro));

        var req = new UpdateStaffMemberRequest("Nombre", null, null, null, null, null, null, "ACTIVO", null);
        assertThrows(StaffMemberNotFoundException.class,
                () -> useCase.update(TENANT, BUSINESS_ID, staffId, req));
    }

    // ── deactivate ───────────────────────────────────────────────────────────

    @Test
    void deactivate_llamaSoftDeleteSiExiste() {
        UUID staffId = UUID.randomUUID();
        when(staffMemberRepository.existsByIdAndBusinessId(staffId, BUSINESS_ID)).thenReturn(true);

        useCase.deactivate(TENANT, BUSINESS_ID, staffId);

        verify(staffMemberRepository).softDelete(staffId);
    }

    @Test
    void deactivate_lanzaStaffNotFound_siNoPertenece() {
        UUID staffId = UUID.randomUUID();
        when(staffMemberRepository.existsByIdAndBusinessId(staffId, BUSINESS_ID)).thenReturn(false);

        assertThrows(StaffMemberNotFoundException.class,
                () -> useCase.deactivate(TENANT, BUSINESS_ID, staffId));

        verify(staffMemberRepository, never()).softDelete(any());
    }

    // ── fixtures ─────────────────────────────────────────────────────────────

    private Business business() {
        return new Business(BUSINESS_ID, TENANT, "Negocio Test", null, null,
                List.of(), true, null, null, null, null, null, null, null, null, null, null);
    }

    private StaffMember staffMember(UUID businessId) {
        return new StaffMember(UUID.randomUUID(), businessId, "Staff Test",
                "Rol", null, null, null, null, null, "ACTIVO", null,
                null, LocalDateTime.now().minusDays(1), LocalDateTime.now().minusDays(1), null);
    }

    private StaffMember staffMemberWithId(UUID id, UUID businessId) {
        return new StaffMember(id, businessId, "Staff Test",
                "Rol", null, null, null, null, null, "ACTIVO", null,
                null, LocalDateTime.now().minusDays(1), LocalDateTime.now().minusDays(1), null);
    }
}

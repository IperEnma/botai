package com.botai.agenda.application.usecase.staff;

import com.botai.agenda.domain.model.StaffMember;
import com.botai.agenda.domain.repository.StaffMemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests de {@link ListPublicStaffUseCase}. Sin Spring.
 */
class ListPublicStaffUseCaseTest {

    private StaffMemberRepository staffMemberRepository;
    private ListPublicStaffUseCase useCase;

    @BeforeEach
    void setUp() {
        staffMemberRepository = mock(StaffMemberRepository.class);
        useCase = new ListPublicStaffUseCase(staffMemberRepository);
    }

    @Test
    void execute_devuelveSoloActivosSinDeletedAt() {
        UUID businessId = UUID.randomUUID();
        List<StaffMember> activos = List.of(
                staffMember(businessId, true),
                staffMember(businessId, true)
        );
        when(staffMemberRepository.findActiveByBusinessId(businessId)).thenReturn(activos);

        List<StaffMember> result = useCase.execute(businessId);

        assertEquals(2, result.size());
        verify(staffMemberRepository).findActiveByBusinessId(businessId);
    }

    @Test
    void execute_devuelveListaVaciaParaBusinessSinStaff() {
        UUID businessId = UUID.randomUUID();
        when(staffMemberRepository.findActiveByBusinessId(businessId)).thenReturn(List.of());

        List<StaffMember> result = useCase.execute(businessId);

        assertTrue(result.isEmpty());
    }

    private StaffMember staffMember(UUID businessId, boolean activo) {
        return new StaffMember(UUID.randomUUID(), businessId, "Staff Test",
                "Estilista", null, activo, null,
                LocalDateTime.now().minusDays(1), LocalDateTime.now().minusDays(1));
    }
}

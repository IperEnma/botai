package com.botai.application.agenda.usecase.staff;

import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.StaffMemberRepository;
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
        return StaffMember.builder()
                .id(UUID.randomUUID())
                .businessId(businessId)
                .nombre("Staff Test")
                .rol("Estilista")
                .status(activo ? "ACTIVO" : "ARCHIVADO")
                .createdAt(LocalDateTime.now().minusDays(1))
                .updatedAt(LocalDateTime.now().minusDays(1))
                .build();
    }
}

package com.botai.application.chatbot.service.agenda;

import com.botai.infrastructure.agenda.persistence.entity.BusinessHoursEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaBusinessHoursJpaRepository;
import com.botai.infrastructure.agenda.support.AgendaPrimaryBusinessResolver;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgendaHorarioTextServiceTest {

    @Mock
    AgendaBusinessHoursJpaRepository hoursRepository;
    @Mock
    AgendaPrimaryBusinessResolver primaryBusinessResolver;

    @InjectMocks
    AgendaHorarioTextService service;

    @Test
    void formatHorarioForTenant_incluyeSegundoTramoYResumen() {
        UUID businessId = UUID.randomUUID();
        String tenantId = "tenant-1";
        when(primaryBusinessResolver.findPrimaryBusinessId(tenantId)).thenReturn(Optional.of(businessId));
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
            openDay(businessId, 0, LocalTime.of(9, 0), LocalTime.of(12, 0), LocalTime.of(14, 0), LocalTime.of(18, 0)),
            closedDay(businessId, 1)
        ));

        String text = service.formatHorarioForTenant(tenantId).orElseThrow();

        assertThat(text).contains("Lunes: 09:00 - 12:00 y 14:00 - 18:00");
        assertThat(text).contains("Martes: Cerrado");
        assertThat(text).contains("hay 1 día(s) con horario de atención configurado");
    }

    private static BusinessHoursEntity openDay(UUID businessId, int dia, LocalTime a1, LocalTime c1, LocalTime a2, LocalTime c2) {
        BusinessHoursEntity e = new BusinessHoursEntity();
        e.setBusinessId(businessId);
        e.setDiaSemana(dia);
        e.setApertura(a1);
        e.setCierre(c1);
        e.setApertura2(a2);
        e.setCierre2(c2);
        e.setCerrado(false);
        return e;
    }

    private static BusinessHoursEntity closedDay(UUID businessId, int dia) {
        BusinessHoursEntity e = new BusinessHoursEntity();
        e.setBusinessId(businessId);
        e.setDiaSemana(dia);
        e.setCerrado(true);
        return e;
    }
}

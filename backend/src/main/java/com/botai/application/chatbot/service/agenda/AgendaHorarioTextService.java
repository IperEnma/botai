package com.botai.application.chatbot.service.agenda;

import com.botai.infrastructure.agenda.persistence.entity.BusinessHoursEntity;
import com.botai.infrastructure.agenda.persistence.jpa.AgendaBusinessHoursJpaRepository;
import com.botai.infrastructure.agenda.support.AgendaPrimaryBusinessResolver;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Texto de horarios de agenda para RAG y tool {@code getHorario} (fuente viva en BD, no solo chunks).
 */
@Component
public class AgendaHorarioTextService {

    private static final String[] DAY_NAMES_ES =
        {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};

    private final AgendaBusinessHoursJpaRepository hoursRepository;
    private final AgendaPrimaryBusinessResolver primaryBusinessResolver;

    public AgendaHorarioTextService(AgendaBusinessHoursJpaRepository hoursRepository,
                                    AgendaPrimaryBusinessResolver primaryBusinessResolver) {
        this.hoursRepository = hoursRepository;
        this.primaryBusinessResolver = primaryBusinessResolver;
    }

    public Optional<String> formatHorarioForTenant(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return Optional.empty();
        }
        return primaryBusinessResolver.findPrimaryBusinessId(tenantId)
            .flatMap(this::formatHorarioForBusiness);
    }

    public Optional<String> formatHorarioForBusiness(UUID businessId) {
        List<BusinessHoursEntity> hours = hoursRepository.findByBusinessId(businessId).stream()
            .sorted(Comparator.comparingInt(BusinessHoursEntity::getDiaSemana))
            .toList();
        if (hours.isEmpty()) {
            return Optional.empty();
        }
        List<String> lines = new ArrayList<>();
        lines.add("Horario de atención del negocio:");
        int openDays = 0;
        for (BusinessHoursEntity h : hours) {
            String line = formatDayLine(h);
            lines.add(line);
            if (!line.endsWith("Cerrado")) {
                openDays++;
            }
        }
        if (openDays == 0) {
            lines.add("Resumen: en agenda todos los días figuran como cerrado.");
        } else {
            lines.add("Resumen: hay " + openDays + " día(s) con horario de atención configurado.");
        }
        return Optional.of(String.join("\n", lines));
    }

    private static String formatDayLine(BusinessHoursEntity h) {
        int d = h.getDiaSemana();
        String label = (d >= 0 && d <= 6) ? DAY_NAMES_ES[d] : "Día " + d;
        if (h.isCerrado()) {
            return label + ": Cerrado";
        }
        if (h.getApertura() == null || h.getCierre() == null) {
            return label + ": Cerrado";
        }
        String base = label + ": " + h.getApertura() + " - " + h.getCierre();
        if (h.getApertura2() != null && h.getCierre2() != null) {
            return base + " y " + h.getApertura2() + " - " + h.getCierre2();
        }
        return base;
    }
}

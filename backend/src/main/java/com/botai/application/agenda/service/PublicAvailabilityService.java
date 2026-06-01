package com.botai.application.agenda.service;

import com.botai.application.agenda.dto.AvailabilitySlotResponse;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.model.StaffMember;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Calcula turnos disponibles para el flujo público de reserva (sin auth).
 */
@Service
public class PublicAvailabilityService {

    private static final String[] DAY_KEYS =
            {"lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"};

    private final BusinessHoursRepository hoursRepository;
    private final BookingRepository bookingRepository;
    private final StaffMemberRepository staffMemberRepository;
    private final ObjectMapper objectMapper;

    public PublicAvailabilityService(BusinessHoursRepository hoursRepository,
                                       BookingRepository bookingRepository,
                                       StaffMemberRepository staffMemberRepository,
                                       ObjectMapper objectMapper) {
        this.hoursRepository = hoursRepository;
        this.bookingRepository = bookingRepository;
        this.staffMemberRepository = staffMemberRepository;
        this.objectMapper = objectMapper;
    }

    public List<AvailabilitySlotResponse> computeSlots(UUID businessId,
                                                       int serviceDurationMin,
                                                       UUID staffMemberId,
                                                       LocalDate date) {
        if (serviceDurationMin <= 0) {
            return List.of();
        }

        int diaSemana = date.getDayOfWeek().getValue() - 1;
        List<BusinessHours> allHours = hoursRepository.findByBusinessId(businessId);
        Optional<BusinessHours> dayHours = allHours.stream()
                .filter(h -> h.getDiaSemana() == diaSemana)
                .findFirst();

        if (dayHours.isEmpty()) {
            // Negocio con horarios guardados pero sin fila para este día → cerrado.
            if (!allHours.isEmpty()) {
                return List.of();
            }
            // Sin configuración de horarios: no inventar turnos por defecto.
            return List.of();
        }

        BusinessHours hours = dayHours.get();
        if (hours.isCerrado()) {
            return List.of();
        }

        List<TimeRange> ranges = openRanges(hours);
        if (ranges.isEmpty()) {
            return List.of();
        }

        if (staffMemberId != null) {
            ranges = applyStaffSchedule(staffMemberId, diaSemana, ranges);
            if (ranges.isEmpty()) {
                return List.of();
            }
        }

        LocalDateTime dayStart = date.atStartOfDay();
        LocalDateTime dayEnd = dayStart.plusDays(1);
        List<Booking> busyBookings = bookingRepository
                .findAllByBusinessIdAndFecha(businessId, dayStart, dayEnd)
                .stream()
                .filter(b -> b.getEstado() == BookingEstado.PENDING
                        || b.getEstado() == BookingEstado.CONFIRMED)
                .filter(b -> staffMemberId == null
                        || staffMemberId.equals(b.getStaffMemberId()))
                .toList();

        List<AvailabilitySlotResponse> slots = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        for (TimeRange range : ranges) {
            LocalDateTime cursor = date.atTime(range.from());
            LocalDateTime rangeEnd = date.atTime(range.to());
            while (!cursor.plusMinutes(serviceDurationMin).isAfter(rangeEnd)) {
                LocalDateTime slotStart = cursor;
                LocalDateTime slotEnd = cursor.plusMinutes(serviceDurationMin);
                if (!slotStart.isBefore(now)) {
                    boolean busy = busyBookings.stream().anyMatch(b ->
                            slotStart.isBefore(b.getFechaHoraFin())
                                    && slotEnd.isAfter(b.getFechaHoraInicio()));
                    if (!busy) {
                        slots.add(new AvailabilitySlotResponse(
                                slotStart.toString(), slotEnd.toString()));
                    }
                }
                cursor = slotEnd;
            }
        }
        return slots;
    }

    private List<TimeRange> openRanges(BusinessHours hours) {
        List<TimeRange> ranges = new ArrayList<>();
        addRangeIfValid(ranges, hours.getApertura(), hours.getCierre());
        addRangeIfValid(ranges, hours.getApertura2(), hours.getCierre2());
        return ranges;
    }

    private void addRangeIfValid(List<TimeRange> ranges, LocalTime from, LocalTime to) {
        if (from == null || to == null || !from.isBefore(to)) {
            return;
        }
        ranges.add(new TimeRange(from, to));
    }

    private List<TimeRange> applyStaffSchedule(UUID staffMemberId,
                                               int diaSemana,
                                               List<TimeRange> businessRanges) {
        Optional<StaffMember> staffOpt = staffMemberRepository.findById(staffMemberId);
        if (staffOpt.isEmpty() || staffOpt.get().getCustomSchedule() == null) {
            return businessRanges;
        }
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> sched = objectMapper.readValue(
                    staffOpt.get().getCustomSchedule(), Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> dayEntry =
                    (Map<String, Object>) sched.get(DAY_KEYS[diaSemana]);
            if (dayEntry == null || !Boolean.TRUE.equals(dayEntry.get("open"))) {
                return List.of();
            }
            String fromStr = (String) dayEntry.get("from");
            String toStr = (String) dayEntry.get("to");
            if (fromStr == null || toStr == null) {
                return List.of();
            }
            LocalTime staffFrom = LocalTime.parse(fromStr);
            LocalTime staffTo = LocalTime.parse(toStr);
            if (!staffFrom.isBefore(staffTo)) {
                return List.of();
            }
            List<TimeRange> clipped = new ArrayList<>();
            for (TimeRange br : businessRanges) {
                LocalTime from = staffFrom.isAfter(br.from()) ? staffFrom : br.from();
                LocalTime to = staffTo.isBefore(br.to()) ? staffTo : br.to();
                if (from.isBefore(to)) {
                    clipped.add(new TimeRange(from, to));
                }
            }
            return clipped;
        } catch (Exception ignored) {
            return businessRanges;
        }
    }

    private record TimeRange(LocalTime from, LocalTime to) {}
}

package com.botai.application.agenda.service;

import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessHoursRepository;
import com.botai.domain.agenda.repository.StaffMemberRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PublicAvailabilityServiceTest {

    private BusinessHoursRepository hoursRepository;
    private BookingRepository bookingRepository;
    private StaffMemberRepository staffMemberRepository;
    private PublicAvailabilityService service;

    private final UUID businessId = UUID.randomUUID();
    private final UUID serviceId = UUID.randomUUID();
    private final UUID staffA = UUID.randomUUID();
    private final UUID staffB = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        hoursRepository = mock(BusinessHoursRepository.class);
        bookingRepository = mock(BookingRepository.class);
        staffMemberRepository = mock(StaffMemberRepository.class);
        service = new PublicAvailabilityService(
                hoursRepository, bookingRepository, staffMemberRepository, new ObjectMapper());
        when(bookingRepository.findAllByBusinessIdAndFecha(eq(businessId), any(), any()))
                .thenReturn(List.of());
    }

    @Test
    void closedDay_returnsNoSlots() {
        var day = LocalDate.now().plusDays(7);
        int diaSemana = day.getDayOfWeek().getValue() - 1;
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
                new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                        LocalTime.of(9, 0), LocalTime.of(13, 0), null, null, true)
        ));

        var slots = service.computeSlots(businessId, 30, null, day);
        assertThat(slots).isEmpty();
    }

    @Test
    void missingDayWhenHoursConfigured_returnsNoSlots() {
        var day = LocalDate.now().plusDays(7);
        int otherDay = (day.getDayOfWeek().getValue()) % 7;
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
                new BusinessHours(UUID.randomUUID(), businessId, otherDay,
                        LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false)
        ));

        var slots = service.computeSlots(businessId, 30, null, day);
        assertThat(slots).isEmpty();
    }

    @Test
    void noHoursConfigured_returnsNoSlots_notDefaults() {
        var day = LocalDate.now().plusDays(7);
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of());

        var slots = service.computeSlots(businessId, 30, null, day);
        assertThat(slots).isEmpty();
    }

    @Test
    void openDayWithBreak_generatesSlotsInBothRanges() {
        var day = LocalDate.now().plusDays(7);
        int diaSemana = day.getDayOfWeek().getValue() - 1;
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
                new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                        LocalTime.of(9, 0), LocalTime.of(13, 0),
                        LocalTime.of(15, 0), LocalTime.of(18, 0), false)
        ));

        var slots = service.computeSlots(businessId, 60, null, day);
        assertThat(slots).isNotEmpty();
        assertThat(slots.get(0).inicio()).contains("T09:00");
        assertThat(slots.stream().anyMatch(s -> s.inicio().contains("T15:00"))).isTrue();
    }

    @Test
    void busyBooking_excludesOverlappingSlot() {
        var day = LocalDate.now().plusDays(7);
        int diaSemana = day.getDayOfWeek().getValue() - 1;
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
                new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                        LocalTime.of(9, 0), LocalTime.of(12, 0), null, null, false)
        ));
        var busy = new Booking(
                UUID.randomUUID(), businessId, serviceId,
                UUID.randomUUID(), null, null,
                day.atTime(9, 0),
                day.atTime(10, 0),
                BookingEstado.CONFIRMED,
                null, null, null, null, null);
        when(bookingRepository.findAllByBusinessIdAndFecha(eq(businessId), any(), any()))
                .thenReturn(List.of(busy));

        var slots = service.computeSlots(businessId, 60, null, day);
        assertThat(slots.stream().noneMatch(s -> s.inicio().contains("T09:00"))).isTrue();
        assertThat(slots.stream().anyMatch(s -> s.inicio().contains("T10:00"))).isTrue();
    }

    @Test
    void anyStaff_unionShowsSlotWhenOneProfessionalIsFree() {
        var day = LocalDate.now().plusDays(7);
        int diaSemana = day.getDayOfWeek().getValue() - 1;
        when(hoursRepository.findByBusinessId(businessId)).thenReturn(List.of(
                new BusinessHours(UUID.randomUUID(), businessId, diaSemana,
                        LocalTime.of(9, 0), LocalTime.of(12, 0), null, null, false)
        ));
        var busyStaffA = new Booking(
                UUID.randomUUID(), businessId, serviceId,
                UUID.randomUUID(), null, staffA,
                day.atTime(9, 0),
                day.atTime(10, 0),
                BookingEstado.CONFIRMED,
                null, null, null, null, null);
        when(bookingRepository.findAllByBusinessIdAndFecha(eq(businessId), any(), any()))
                .thenReturn(List.of(busyStaffA));

        var slots = service.computeSlots(
                businessId, 60, null, day, ServiceSchedulingMode.BY_STAFF, List.of(staffA, staffB));

        assertThat(slots.stream().anyMatch(s -> s.inicio().contains("T09:00"))).isTrue();
        assertThat(slots.stream().anyMatch(s -> s.inicio().contains("T10:00"))).isTrue();
    }
}

package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.BookingResponse;
import com.botai.agenda.domain.model.Booking;

public final class BookingDtoMapper {

    private BookingDtoMapper() {
    }

    public static BookingResponse toResponse(Booking booking) {
        if (booking == null) return null;
        return new BookingResponse(
                booking.getId(),
                booking.getBusinessId(),
                booking.getServiceId(),
                booking.getUserId(),
                booking.getSubscriptionId(),
                booking.getStaffMemberId(),
                booking.getFechaHoraInicio(),
                booking.getFechaHoraFin(),
                booking.getEstado(),
                booking.getNotas(),
                booking.getCanceladaAt(),
                booking.getCompletadaAt(),
                booking.getCreatedAt(),
                booking.getUpdatedAt()
        );
    }
}

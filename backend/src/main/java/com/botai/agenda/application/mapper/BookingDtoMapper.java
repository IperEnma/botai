package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.BookingResponse;
import com.botai.agenda.domain.model.Booking;
import com.botai.agenda.domain.model.User;

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
                booking.getUpdatedAt(),
                null,
                null,
                null,
                null
        );
    }

    public static BookingResponse toResponse(Booking booking,
                                            String servicioNombre,
                                            User user) {
        BookingResponse base = toResponse(booking);
        if (base == null) return null;
        return new BookingResponse(
                base.id(),
                base.businessId(),
                base.serviceId(),
                base.userId(),
                base.subscriptionId(),
                base.staffMemberId(),
                base.fechaHoraInicio(),
                base.fechaHoraFin(),
                base.estado(),
                base.notas(),
                base.canceladaAt(),
                base.completadaAt(),
                base.createdAt(),
                base.updatedAt(),
                servicioNombre,
                user != null ? user.getNombre() : null,
                user != null ? user.getEmail() : null,
                user != null ? user.getTelefono() : null
        );
    }
}

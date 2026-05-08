package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.Booking;
import com.botai.infrastructure.agenda.persistence.entity.BookingEntity;

public final class BookingMapper {

    private BookingMapper() {
    }

    public static Booking toDomain(BookingEntity e) {
        if (e == null) return null;
        return new Booking(
                e.getId(),
                e.getBusinessId(),
                e.getServiceId(),
                e.getUserId(),
                e.getSubscriptionId(),
                e.getStaffMemberId(),
                e.getFechaHoraInicio(),
                e.getFechaHoraFin(),
                e.getEstado(),
                e.getNotas(),
                e.getCanceladaAt(),
                e.getCompletadaAt(),
                e.getCreatedAt(),
                e.getUpdatedAt()
        );
    }

    public static BookingEntity toEntity(Booking b) {
        if (b == null) return null;
        BookingEntity e = new BookingEntity();
        e.setId(b.getId());
        e.setBusinessId(b.getBusinessId());
        e.setServiceId(b.getServiceId());
        e.setUserId(b.getUserId());
        e.setSubscriptionId(b.getSubscriptionId());
        e.setStaffMemberId(b.getStaffMemberId());
        e.setFechaHoraInicio(b.getFechaHoraInicio());
        e.setFechaHoraFin(b.getFechaHoraFin());
        e.setEstado(b.getEstado());
        e.setNotas(b.getNotas());
        e.setCanceladaAt(b.getCanceladaAt());
        e.setCompletadaAt(b.getCompletadaAt());
        // createdAt / updatedAt los maneja @EntityListeners de BaseAuditableEntity.
        return e;
    }
}

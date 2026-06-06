package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Reseña inmutable que un cliente deja tras una reserva COMPLETADA.
 * Invariante: {@code 1 <= rating <= 5}.
 */
public final class Review {

    private final UUID id;
    private final UUID businessId;
    private final UUID bookingId;
    private final UUID agendaUserId;
    private final UUID staffMemberId;
    private final int rating;
    private final String comentario;
    private final LocalDateTime createdAt;

    public Review(UUID id,
                  UUID businessId,
                  UUID bookingId,
                  UUID agendaUserId,
                  UUID staffMemberId,
                  int rating,
                  String comentario,
                  LocalDateTime createdAt) {
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("El rating debe estar entre 1 y 5");
        }
        this.id = id;
        this.businessId = businessId;
        this.bookingId = bookingId;
        this.agendaUserId = agendaUserId;
        this.staffMemberId = staffMemberId;
        this.rating = rating;
        this.comentario = comentario;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public UUID getBookingId() { return bookingId; }
    public UUID getAgendaUserId() { return agendaUserId; }
    public UUID getStaffMemberId() { return staffMemberId; }
    public int getRating() { return rating; }
    public String getComentario() { return comentario; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}

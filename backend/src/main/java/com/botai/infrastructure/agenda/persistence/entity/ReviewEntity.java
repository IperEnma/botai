package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Reseña inmutable: no extiende {@link BaseAuditableEntity} porque no tiene
 * {@code updated_at} ni {@code deleted_at}. El UUID se asigna en el adapter.
 *
 * <p>Esquema generado por el ORM ({@code ddl-auto: update}); sin migración Flyway.
 * El UNIQUE de {@code booking_id} y los índices se declaran aquí.</p>
 */
@Entity
@Table(
    name = "agenda_reviews",
    indexes = {
        @Index(name = "idx_agenda_reviews_business", columnList = "business_id, created_at")
    }
)
public class ReviewEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false, updatable = false)
    private UUID businessId;

    @Column(name = "booking_id", nullable = false, updatable = false, unique = true)
    private UUID bookingId;

    @Column(name = "agenda_user_id", nullable = false, updatable = false)
    private UUID agendaUserId;

    @Column(name = "staff_member_id", updatable = false)
    private UUID staffMemberId;

    @Column(name = "rating", nullable = false, updatable = false)
    private int rating;

    @Column(name = "comentario", columnDefinition = "text", updatable = false)
    private String comentario;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public UUID getBookingId() { return bookingId; }
    public void setBookingId(UUID bookingId) { this.bookingId = bookingId; }
    public UUID getAgendaUserId() { return agendaUserId; }
    public void setAgendaUserId(UUID agendaUserId) { this.agendaUserId = agendaUserId; }
    public UUID getStaffMemberId() { return staffMemberId; }
    public void setStaffMemberId(UUID staffMemberId) { this.staffMemberId = staffMemberId; }
    public int getRating() { return rating; }
    public void setRating(int rating) { this.rating = rating; }
    public String getComentario() { return comentario; }
    public void setComentario(String comentario) { this.comentario = comentario; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

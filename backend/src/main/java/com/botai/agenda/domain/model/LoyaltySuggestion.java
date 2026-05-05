package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Sugerencia de fidelización generada cuando un usuario alcanza el umbral de
 * asistencias configurado en {@link BusinessSettings#getLoyaltyMinAttendances()}.
 *
 * <p>Inmutable. El estado puede transitar: PENDING → SENT o PENDING → DISMISSED.
 * Las transiciones se generan mediante nuevas instancias (no mutación).</p>
 */
public final class LoyaltySuggestion {

    private final UUID id;
    private final UUID businessId;
    private final UUID userId;
    private final String triggerRule;
    private final LoyaltySuggestionEstado estado;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public LoyaltySuggestion(UUID id,
                              UUID businessId,
                              UUID userId,
                              String triggerRule,
                              LoyaltySuggestionEstado estado,
                              LocalDateTime createdAt,
                              LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.triggerRule = Objects.requireNonNull(triggerRule, "triggerRule");
        this.estado = Objects.requireNonNull(estado, "estado");
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public UUID getUserId() { return userId; }
    public String getTriggerRule() { return triggerRule; }
    public LoyaltySuggestionEstado getEstado() { return estado; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public LoyaltySuggestion withEstado(LoyaltySuggestionEstado nuevoEstado) {
        return new LoyaltySuggestion(id, businessId, userId, triggerRule,
                nuevoEstado, createdAt, updatedAt);
    }
}

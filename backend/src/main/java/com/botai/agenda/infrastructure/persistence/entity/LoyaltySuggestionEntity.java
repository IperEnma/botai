package com.botai.agenda.infrastructure.persistence.entity;

import com.botai.agenda.domain.model.LoyaltySuggestionEstado;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "agenda_loyalty_suggestions")
public class LoyaltySuggestionEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "trigger_rule", nullable = false, length = 60)
    private String triggerRule;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 20)
    private LoyaltySuggestionEstado estado;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getTriggerRule() { return triggerRule; }
    public void setTriggerRule(String triggerRule) { this.triggerRule = triggerRule; }
    public LoyaltySuggestionEstado getEstado() { return estado; }
    public void setEstado(LoyaltySuggestionEstado estado) { this.estado = estado; }
}

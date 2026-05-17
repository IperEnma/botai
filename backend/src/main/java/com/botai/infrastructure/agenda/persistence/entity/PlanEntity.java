package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import com.botai.domain.agenda.model.PlanTier;
import com.botai.domain.agenda.model.PlanTipo;

@Entity
@Table(
        name = "agenda_plans",
        indexes = @Index(name = "idx_agenda_plans_business_activo", columnList = "business_id, activo"))
@Check(constraints = "tipo IN ('ILIMITADO_MENSUAL','POR_CREDITOS','SOLO_RESERVA','MIXTO')")
@Check(constraints = "tier IS NULL OR tier IN ('VIP','GOLDEN','PLATA')")
@Check(constraints = "validez_dias > 0")
@Check(constraints = "precio >= 0")
@Check(constraints = "total_creditos IS NULL OR total_creditos >= 0")
public class PlanEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "nombre_plan", nullable = false)
    private String nombrePlan;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false, length = 24)
    private PlanTipo tipo;

    @Enumerated(EnumType.STRING)
    @Column(name = "tier", length = 16)
    private PlanTier tier;

    @Column(name = "total_creditos")
    private Integer totalCreditos;

    @Column(name = "validez_dias", nullable = false)
    private int validezDias;

    @Column(name = "precio", precision = 12, scale = 2, nullable = false)
    private BigDecimal precio;

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public String getNombrePlan() { return nombrePlan; }
    public void setNombrePlan(String nombrePlan) { this.nombrePlan = nombrePlan; }
    public PlanTipo getTipo() { return tipo; }
    public void setTipo(PlanTipo tipo) { this.tipo = tipo; }
    public PlanTier getTier() { return tier; }
    public void setTier(PlanTier tier) { this.tier = tier; }
    public Integer getTotalCreditos() { return totalCreditos; }
    public void setTotalCreditos(Integer totalCreditos) { this.totalCreditos = totalCreditos; }
    public int getValidezDias() { return validezDias; }
    public void setValidezDias(int validezDias) { this.validezDias = validezDias; }
    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}

package com.botai.domain.agenda.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Plan que ofrece un negocio (p. ej. "Ilimitado Gold", "10 créditos mensual").
 *
 * <p>Modelo de dominio inmutable. Las validaciones de consistencia entre
 * {@code tipo} y {@code totalCreditos} viven a nivel de caso de uso / dominio
 * (p. ej. {@code POR_CREDITOS} exige {@code totalCreditos > 0}).</p>
 */
public final class Plan {

    private final UUID id;
    private final UUID businessId;
    private final String nombrePlan;
    private final PlanTipo tipo;
    private final PlanTier tier;
    private final Integer totalCreditos;
    private final int validezDias;
    private final BigDecimal precio;
    private final boolean activo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Plan(UUID id,
                UUID businessId,
                String nombrePlan,
                PlanTipo tipo,
                PlanTier tier,
                Integer totalCreditos,
                int validezDias,
                BigDecimal precio,
                boolean activo,
                LocalDateTime createdAt,
                LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.nombrePlan = Objects.requireNonNull(nombrePlan, "nombrePlan");
        this.tipo = Objects.requireNonNull(tipo, "tipo");
        this.tier = tier; // opcional
        this.totalCreditos = totalCreditos; // NULL válido para ILIMITADO_MENSUAL / SOLO_RESERVA
        if (validezDias <= 0) {
            throw new IllegalArgumentException("validezDias debe ser > 0");
        }
        this.validezDias = validezDias;
        this.precio = Objects.requireNonNull(precio, "precio");
        if (precio.signum() < 0) {
            throw new IllegalArgumentException("precio no puede ser negativo");
        }
        this.activo = activo;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getNombrePlan() { return nombrePlan; }
    public PlanTipo getTipo() { return tipo; }
    public PlanTier getTier() { return tier; }
    public Integer getTotalCreditos() { return totalCreditos; }
    public int getValidezDias() { return validezDias; }
    public BigDecimal getPrecio() { return precio; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

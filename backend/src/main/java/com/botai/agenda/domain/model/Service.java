package com.botai.agenda.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

public final class Service {

    private final UUID id;
    private final UUID businessId;
    private final String nombre;
    private final String descripcion;
    private final int duracionMin;
    private final BigDecimal precio;
    private final boolean activo;
    private final LocalDateTime deletedAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Service(UUID id, UUID businessId, String nombre, String descripcion,
                   int duracionMin, BigDecimal precio, boolean activo,
                   LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.nombre = Objects.requireNonNull(nombre, "nombre");
        this.descripcion = descripcion;
        if (duracionMin <= 0) {
            throw new IllegalArgumentException("duracionMin debe ser positivo");
        }
        this.duracionMin = duracionMin;
        this.precio = precio;
        this.activo = activo;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getNombre() { return nombre; }
    public String getDescripcion() { return descripcion; }
    public int getDuracionMin() { return duracionMin; }
    public BigDecimal getPrecio() { return precio; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

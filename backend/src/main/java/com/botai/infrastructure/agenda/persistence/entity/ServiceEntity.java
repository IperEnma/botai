package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * <p><b>Por qué {@code @Entity(name = "AgendaService")}:</b> el bot tiene una
 * clase con el mismo simple name en
 * {@code com.botai.infrastructure.chatbot.persistence.entity.ServiceEntity}.
 * Hibernate exige que el <i>entity name</i> sea único en el {@code EntityManagerFactory}.
 * Como ambas clases se llaman {@code ServiceEntity} y por default Hibernate usa
 * el simple name, tendríamos un {@code DuplicateMappingException} al arrancar
 * con las dos entidades en el scan. Acá forzamos un entity name distinto
 * ({@code "AgendaService"}) para coexistir con el del bot. No afecta el nombre
 * de la tabla (ya declarado en {@code @Table}) — solo afecta JPQL, y en AGENDA
 * no hay queries JPQL contra {@code ServiceEntity}.</p>
 */
@Entity(name = "AgendaService")
@Table(name = "agenda_services")
public class ServiceEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "descripcion", columnDefinition = "text")
    private String descripcion;

    @Column(name = "duracion_min", nullable = false)
    private int duracionMin;

    @Column(name = "precio", precision = 12, scale = 2)
    private BigDecimal precio;

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public int getDuracionMin() { return duracionMin; }
    public void setDuracionMin(int duracionMin) { this.duracionMin = duracionMin; }
    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}

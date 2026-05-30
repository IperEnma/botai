package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;

import java.time.LocalTime;
import java.util.UUID;

@Entity(name = "AgendaBusinessHoursEntity")
@Table(
        name = "agenda_business_hours",
        uniqueConstraints = @UniqueConstraint(columnNames = {"business_id", "dia_semana"}),
        indexes = @Index(name = "idx_business_hours_business_id", columnList = "business_id"))
@Check(constraints = "dia_semana BETWEEN 0 AND 6")
public class BusinessHoursEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "dia_semana", nullable = false)
    private int diaSemana;

    @Column(name = "apertura")
    private LocalTime apertura;

    @Column(name = "cierre")
    private LocalTime cierre;

    /** Start of the second range (after a break), null when there is no break. */
    @Column(name = "apertura2")
    private LocalTime apertura2;

    /** End of the second range (after a break), null when there is no break. */
    @Column(name = "cierre2")
    private LocalTime cierre2;

    @Column(name = "cerrado", nullable = false)
    private boolean cerrado;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public int getDiaSemana() { return diaSemana; }
    public void setDiaSemana(int diaSemana) { this.diaSemana = diaSemana; }
    public LocalTime getApertura() { return apertura; }
    public void setApertura(LocalTime apertura) { this.apertura = apertura; }
    public LocalTime getCierre() { return cierre; }
    public void setCierre(LocalTime cierre) { this.cierre = cierre; }
    public LocalTime getApertura2() { return apertura2; }
    public void setApertura2(LocalTime apertura2) { this.apertura2 = apertura2; }
    public LocalTime getCierre2() { return cierre2; }
    public void setCierre2(LocalTime cierre2) { this.cierre2 = cierre2; }
    public boolean isCerrado() { return cerrado; }
    public void setCerrado(boolean cerrado) { this.cerrado = cerrado; }
}

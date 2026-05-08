package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalTime;
import java.util.UUID;

@Entity(name = "AgendaBusinessHoursEntity")
@Table(name = "agenda_business_hours")
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
    public boolean isCerrado() { return cerrado; }
    public void setCerrado(boolean cerrado) { this.cerrado = cerrado; }
}

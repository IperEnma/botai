package com.botai.infrastructure.agenda.persistence.entity;

import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationEstado;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "agenda_notifications")
public class NotificationEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "canal", nullable = false, length = 20)
    private NotificationCanal canal;

    @Column(name = "titulo", nullable = false, length = 255)
    private String titulo;

    @Column(name = "cuerpo", nullable = false, columnDefinition = "TEXT")
    private String cuerpo;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 20)
    private NotificationEstado estado;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public NotificationCanal getCanal() { return canal; }
    public void setCanal(NotificationCanal canal) { this.canal = canal; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getCuerpo() { return cuerpo; }
    public void setCuerpo(String cuerpo) { this.cuerpo = cuerpo; }
    public NotificationEstado getEstado() { return estado; }
    public void setEstado(NotificationEstado estado) { this.estado = estado; }
}

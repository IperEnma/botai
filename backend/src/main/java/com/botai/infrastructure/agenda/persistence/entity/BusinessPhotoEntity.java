package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity(name = "AgendaBusinessPhotoEntity")
@Table(
        name = "agenda_business_photos",
        indexes = @Index(name = "idx_agenda_business_photos_business", columnList = "business_id, orden"))
public class BusinessPhotoEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "url", nullable = false, length = 500)
    private String url;

    @Column(name = "orden", nullable = false)
    private int orden;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    public int getOrden() { return orden; }
    public void setOrden(int orden) { this.orden = orden; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

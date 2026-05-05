package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.UUID;

public final class BusinessPhoto {

    private final UUID id;
    private final UUID businessId;
    private final String url;
    private final int orden;
    private final LocalDateTime createdAt;

    public BusinessPhoto(UUID id, UUID businessId, String url, int orden, LocalDateTime createdAt) {
        this.id = id;
        this.businessId = businessId;
        this.url = url;
        this.orden = orden;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getUrl() { return url; }
    public int getOrden() { return orden; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}

package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

public final class Business {

    private final UUID id;
    private final String tenantId;
    private final String nombre;
    private final String descripcion;
    private final UUID ownerUserId;
    private final List<String> searchTags;
    private final boolean activo;
    private final String logoUrl;
    private final String colorPrimario;
    private final String instagramUrl;
    private final String tiktokUrl;
    private final String facebookUrl;
    private final String colorFondo;
    private final String fontFamily;
    private final String publicSlug;
    private final LocalDateTime deletedAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<String> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    String publicSlug,
                    LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.nombre = Objects.requireNonNull(nombre, "nombre");
        this.descripcion = descripcion;
        this.ownerUserId = ownerUserId;
        this.searchTags = searchTags == null ? List.of() : List.copyOf(searchTags);
        this.activo = activo;
        this.logoUrl = logoUrl;
        this.colorPrimario = colorPrimario;
        this.instagramUrl = instagramUrl;
        this.tiktokUrl = tiktokUrl;
        this.facebookUrl = facebookUrl;
        this.colorFondo = colorFondo;
        this.fontFamily = fontFamily;
        this.publicSlug = publicSlug;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    /**
     * Backward-compatible constructor (sin {@code publicSlug}).
     * Mantiene tests y casos de uso existentes mientras migran.
     */
    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<String> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this(id, tenantId, nombre, descripcion, ownerUserId, searchTags, activo,
                logoUrl, colorPrimario, instagramUrl, tiktokUrl, facebookUrl,
                colorFondo, fontFamily, null,
                deletedAt, createdAt, updatedAt);
    }

    public UUID getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getNombre() { return nombre; }
    public String getDescripcion() { return descripcion; }
    public UUID getOwnerUserId() { return ownerUserId; }
    public List<String> getSearchTags() { return searchTags; }
    public boolean isActivo() { return activo; }
    public String getLogoUrl() { return logoUrl; }
    public String getColorPrimario() { return colorPrimario; }
    public String getInstagramUrl() { return instagramUrl; }
    public String getTiktokUrl() { return tiktokUrl; }
    public String getFacebookUrl() { return facebookUrl; }
    public String getColorFondo() { return colorFondo; }
    public String getFontFamily() { return fontFamily; }
    public String getPublicSlug() { return publicSlug; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

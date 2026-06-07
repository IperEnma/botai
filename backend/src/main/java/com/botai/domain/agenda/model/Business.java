package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;

public final class Business {

    private final UUID id;
    private final String tenantId;
    private final String nombre;
    private final String descripcion;
    private final UUID ownerUserId;
    private final List<SearchTag> searchTags;
    private final boolean activo;
    private final String logoUrl;
    private final String colorPrimario;
    private final String instagramUrl;
    private final String tiktokUrl;
    private final String facebookUrl;
    private final String colorFondo;
    private final String fontFamily;
    private final String publicSlug;
    /** Slug de marca para {@code /reservar?company=}; compartido por sucursales del tenant. */
    private final String companySlug;
    /** PK numérica del bot en tabla {@code bot}; null si el negocio aún no está ligado al workspace del bot. */
    private final Long botId;
    private final String direccion;
    private final String bannerUrl;
    private final LocalDateTime deletedAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<SearchTag> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    String publicSlug,
                    String companySlug,
                    Long botId,
                    String direccion,
                    String bannerUrl,
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
        this.companySlug = companySlug;
        this.botId = botId;
        this.direccion = direccion;
        this.bannerUrl = bannerUrl;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    /**
     * Constructor sin {@code publicSlug} ni {@code botId} (tests y código legado).
     */
    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<SearchTag> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this(id, tenantId, nombre, descripcion, ownerUserId, searchTags, activo,
                logoUrl, colorPrimario, instagramUrl, tiktokUrl, facebookUrl,
                colorFondo, fontFamily, null, null, null, null, null,
                deletedAt, createdAt, updatedAt);
    }

    /** Constructor con {@code publicSlug} sin {@code botId}. */
    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<SearchTag> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    String publicSlug,
                    LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this(id, tenantId, nombre, descripcion, ownerUserId, searchTags, activo,
                logoUrl, colorPrimario, instagramUrl, tiktokUrl, facebookUrl,
                colorFondo, fontFamily, publicSlug, null, null, null, null,
                deletedAt, createdAt, updatedAt);
    }

    /**
     * Constructor con {@code publicSlug}, {@code companySlug} y {@code botId} — sin {@code direccion}/{@code bannerUrl}.
     * Delegado de compatibilidad para código legado.
     */
    public Business(UUID id, String tenantId, String nombre, String descripcion,
                    UUID ownerUserId, List<SearchTag> searchTags, boolean activo,
                    String logoUrl, String colorPrimario,
                    String instagramUrl, String tiktokUrl, String facebookUrl,
                    String colorFondo, String fontFamily,
                    String publicSlug,
                    String companySlug,
                    Long botId,
                    LocalDateTime deletedAt, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this(id, tenantId, nombre, descripcion, ownerUserId, searchTags, activo,
                logoUrl, colorPrimario, instagramUrl, tiktokUrl, facebookUrl,
                colorFondo, fontFamily, publicSlug, companySlug, botId, null, null,
                deletedAt, createdAt, updatedAt);
    }

    public UUID getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getNombre() { return nombre; }
    public String getDescripcion() { return descripcion; }
    public UUID getOwnerUserId() { return ownerUserId; }
    public List<SearchTag> getSearchTags() { return searchTags; }

    public List<String> getProfileTagValues() {
        return searchTags.stream()
                .filter(SearchTag::isProfile)
                .map(SearchTag::value)
                .collect(Collectors.toUnmodifiableList());
    }
    public boolean isActivo() { return activo; }
    public String getLogoUrl() { return logoUrl; }
    public String getColorPrimario() { return colorPrimario; }
    public String getInstagramUrl() { return instagramUrl; }
    public String getTiktokUrl() { return tiktokUrl; }
    public String getFacebookUrl() { return facebookUrl; }
    public String getColorFondo() { return colorFondo; }
    public String getFontFamily() { return fontFamily; }
    public String getPublicSlug() { return publicSlug; }
    public String getCompanySlug() { return companySlug; }
    public Long getBotId() { return botId; }
    public String getDireccion() { return direccion; }
    public String getBannerUrl() { return bannerUrl; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}

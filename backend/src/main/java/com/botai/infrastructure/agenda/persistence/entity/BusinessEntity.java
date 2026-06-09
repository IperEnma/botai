package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(
        name = "agenda_businesses",
        // idx_agenda_businesses_company_slug lo crea V3 como índice PARCIAL
        // (WHERE deleted_at IS NULL AND activo = TRUE); no se declara aquí para
        // evitar colisión de nombre que dejaría sin efecto el parcial.
        indexes = {
                @Index(name = "idx_agenda_businesses_bot_id", columnList = "bot_id")
        })
public class BusinessEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "descripcion", columnDefinition = "text")
    private String descripcion;

    @Column(name = "owner_user_id")
    private UUID ownerUserId;

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Column(name = "color_primario", length = 9)
    private String colorPrimario;

    @Column(name = "instagram_url", length = 500)
    private String instagramUrl;

    @Column(name = "tiktok_url", length = 500)
    private String tiktokUrl;

    @Column(name = "facebook_url", length = 500)
    private String facebookUrl;

    @Column(name = "color_fondo", length = 20)
    private String colorFondo;

    @Column(name = "color_tarjeta", length = 20)
    private String colorTarjeta;

    @Column(name = "font_family", length = 100)
    private String fontFamily;

    @Column(name = "public_slug", length = 180)
    private String publicSlug;

    @Column(name = "company_slug", length = 80)
    private String companySlug;

    /** FK a {@code bot.id}; varios negocios pueden compartir el mismo bot (mismo workspace). */
    @Column(name = "bot_id")
    private Long botId;

    @Column(name = "direccion", columnDefinition = "text")
    private String direccion;

    @Column(name = "banner_url", length = 500)
    private String bannerUrl;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public UUID getOwnerUserId() { return ownerUserId; }
    public void setOwnerUserId(UUID ownerUserId) { this.ownerUserId = ownerUserId; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
    public String getLogoUrl() { return logoUrl; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }
    public String getColorPrimario() { return colorPrimario; }
    public void setColorPrimario(String colorPrimario) { this.colorPrimario = colorPrimario; }
    public String getInstagramUrl() { return instagramUrl; }
    public void setInstagramUrl(String instagramUrl) { this.instagramUrl = instagramUrl; }
    public String getTiktokUrl() { return tiktokUrl; }
    public void setTiktokUrl(String tiktokUrl) { this.tiktokUrl = tiktokUrl; }
    public String getFacebookUrl() { return facebookUrl; }
    public void setFacebookUrl(String facebookUrl) { this.facebookUrl = facebookUrl; }
    public String getColorFondo() { return colorFondo; }
    public void setColorFondo(String colorFondo) { this.colorFondo = colorFondo; }
    public String getColorTarjeta() { return colorTarjeta; }
    public void setColorTarjeta(String colorTarjeta) { this.colorTarjeta = colorTarjeta; }
    public String getFontFamily() { return fontFamily; }
    public void setFontFamily(String fontFamily) { this.fontFamily = fontFamily; }
    public String getPublicSlug() { return publicSlug; }
    public void setPublicSlug(String publicSlug) { this.publicSlug = publicSlug; }
    public String getCompanySlug() { return companySlug; }
    public void setCompanySlug(String companySlug) { this.companySlug = companySlug; }
    public Long getBotId() { return botId; }
    public void setBotId(Long botId) { this.botId = botId; }
    public String getDireccion() { return direccion; }
    public void setDireccion(String direccion) { this.direccion = direccion; }
    public String getBannerUrl() { return bannerUrl; }
    public void setBannerUrl(String bannerUrl) { this.bannerUrl = bannerUrl; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}

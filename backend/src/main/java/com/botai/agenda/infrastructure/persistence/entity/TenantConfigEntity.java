package com.botai.agenda.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "agenda_tenant_config")
public class TenantConfigEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "agenda_enabled", nullable = false)
    private boolean agendaEnabled = false;

    @Column(name = "public_search_enabled", nullable = false)
    private boolean publicSearchEnabled = true;

    @Column(name = "loyalty_engine_enabled", nullable = false)
    private boolean loyaltyEngineEnabled = true;

    @Column(name = "auto_notifications", nullable = false)
    private boolean autoNotifications = true;

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public boolean isAgendaEnabled() { return agendaEnabled; }
    public void setAgendaEnabled(boolean v) { this.agendaEnabled = v; }
    public boolean isPublicSearchEnabled() { return publicSearchEnabled; }
    public void setPublicSearchEnabled(boolean v) { this.publicSearchEnabled = v; }
    public boolean isLoyaltyEngineEnabled() { return loyaltyEngineEnabled; }
    public void setLoyaltyEngineEnabled(boolean v) { this.loyaltyEngineEnabled = v; }
    public boolean isAutoNotifications() { return autoNotifications; }
    public void setAutoNotifications(boolean v) { this.autoNotifications = v; }
}

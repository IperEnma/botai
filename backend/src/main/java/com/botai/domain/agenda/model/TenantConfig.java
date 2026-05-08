package com.botai.domain.agenda.model;

import java.util.Objects;

public final class TenantConfig {

    private final String tenantId;
    private final boolean agendaEnabled;
    private final boolean publicSearchEnabled;
    private final boolean loyaltyEngineEnabled;
    private final boolean autoNotifications;

    public TenantConfig(String tenantId, boolean agendaEnabled, boolean publicSearchEnabled,
                        boolean loyaltyEngineEnabled, boolean autoNotifications) {
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.agendaEnabled = agendaEnabled;
        this.publicSearchEnabled = publicSearchEnabled;
        this.loyaltyEngineEnabled = loyaltyEngineEnabled;
        this.autoNotifications = autoNotifications;
    }

    public static TenantConfig defaultsFor(String tenantId) {
        return new TenantConfig(tenantId, false, true, true, true);
    }

    public String getTenantId() { return tenantId; }
    public boolean isAgendaEnabled() { return agendaEnabled; }
    public boolean isPublicSearchEnabled() { return publicSearchEnabled; }
    public boolean isLoyaltyEngineEnabled() { return loyaltyEngineEnabled; }
    public boolean isAutoNotifications() { return autoNotifications; }
}

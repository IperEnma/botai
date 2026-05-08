package com.botai.domain.agenda.model;

import java.util.Objects;
import java.util.UUID;

public final class BusinessSettings {

    private final UUID businessId;
    private final int hoursCancellationLimit;
    private final int loyaltyMinAttendances;
    private final int loyaltyWindowDays;
    private final int expirationAlertDays;
    private final int expirationAlertCredits;
    private final boolean autoNotifyEnabled;

    public BusinessSettings(UUID businessId, int hoursCancellationLimit,
                            int loyaltyMinAttendances, int loyaltyWindowDays,
                            int expirationAlertDays, int expirationAlertCredits,
                            boolean autoNotifyEnabled) {
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.hoursCancellationLimit = hoursCancellationLimit;
        this.loyaltyMinAttendances = loyaltyMinAttendances;
        this.loyaltyWindowDays = loyaltyWindowDays;
        this.expirationAlertDays = expirationAlertDays;
        this.expirationAlertCredits = expirationAlertCredits;
        this.autoNotifyEnabled = autoNotifyEnabled;
    }

    public static BusinessSettings defaults(UUID businessId) {
        return new BusinessSettings(businessId, 4, 3, 30, 7, 2, true);
    }

    public UUID getBusinessId() { return businessId; }
    public int getHoursCancellationLimit() { return hoursCancellationLimit; }
    public int getLoyaltyMinAttendances() { return loyaltyMinAttendances; }
    public int getLoyaltyWindowDays() { return loyaltyWindowDays; }
    public int getExpirationAlertDays() { return expirationAlertDays; }
    public int getExpirationAlertCredits() { return expirationAlertCredits; }
    public boolean isAutoNotifyEnabled() { return autoNotifyEnabled; }
}

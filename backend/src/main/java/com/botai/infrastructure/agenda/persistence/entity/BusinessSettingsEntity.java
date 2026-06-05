package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Check;

import java.util.UUID;

@Entity
@Table(name = "agenda_business_settings")
@Check(constraints = "hours_cancellation_limit >= 0")
@Check(constraints = "loyalty_min_attendances > 0")
@Check(constraints = "loyalty_window_days > 0")
public class BusinessSettingsEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "business_id", nullable = false, updatable = false)
    private UUID businessId;

    @Column(name = "hours_cancellation_limit", nullable = false)
    private int hoursCancellationLimit = 4;

    @Column(name = "loyalty_min_attendances", nullable = false)
    private int loyaltyMinAttendances = 3;

    @Column(name = "loyalty_window_days", nullable = false)
    private int loyaltyWindowDays = 30;

    @Column(name = "expiration_alert_days", nullable = false)
    private int expirationAlertDays = 7;

    @Column(name = "expiration_alert_credits", nullable = false)
    private int expirationAlertCredits = 2;

    @Column(name = "auto_notify_enabled", nullable = false)
    private boolean autoNotifyEnabled = true;

    @Column(name = "require_booking_confirmation", nullable = false)
    private boolean requireBookingConfirmation = true;

    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public int getHoursCancellationLimit() { return hoursCancellationLimit; }
    public void setHoursCancellationLimit(int v) { this.hoursCancellationLimit = v; }
    public int getLoyaltyMinAttendances() { return loyaltyMinAttendances; }
    public void setLoyaltyMinAttendances(int v) { this.loyaltyMinAttendances = v; }
    public int getLoyaltyWindowDays() { return loyaltyWindowDays; }
    public void setLoyaltyWindowDays(int v) { this.loyaltyWindowDays = v; }
    public int getExpirationAlertDays() { return expirationAlertDays; }
    public void setExpirationAlertDays(int v) { this.expirationAlertDays = v; }
    public int getExpirationAlertCredits() { return expirationAlertCredits; }
    public void setExpirationAlertCredits(int v) { this.expirationAlertCredits = v; }
    public boolean isAutoNotifyEnabled() { return autoNotifyEnabled; }
    public void setAutoNotifyEnabled(boolean v) { this.autoNotifyEnabled = v; }
    public boolean isRequireBookingConfirmation() { return requireBookingConfirmation; }
    public void setRequireBookingConfirmation(boolean v) { this.requireBookingConfirmation = v; }
}

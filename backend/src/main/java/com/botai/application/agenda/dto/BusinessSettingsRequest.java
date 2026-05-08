package com.botai.application.agenda.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record BusinessSettingsRequest(
        @Min(0) int hoursCancellationLimit,
        @Min(1) int loyaltyMinAttendances,
        @Min(1) int loyaltyWindowDays,
        @Min(1) int expirationAlertDays,
        @Min(0) int expirationAlertCredits,
        @NotNull Boolean autoNotifyEnabled
) {}

package com.botai.application.agenda.dto;

import java.util.UUID;

public record BusinessSettingsResponse(
        UUID businessId,
        int hoursCancellationLimit,
        int loyaltyMinAttendances,
        int loyaltyWindowDays,
        int expirationAlertDays,
        int expirationAlertCredits,
        boolean autoNotifyEnabled
) {}

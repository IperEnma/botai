package com.botai.application.agenda.dto;

import java.util.List;

public record VerifyPhoneVerificationResponse(
        String clientSessionToken,
        PublicClientProfileResponse client,
        List<BookingResponse> bookings
) {}

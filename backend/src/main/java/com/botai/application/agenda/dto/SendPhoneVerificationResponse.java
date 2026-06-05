package com.botai.application.agenda.dto;

public record SendPhoneVerificationResponse(
        boolean sent,
        String message
) {}

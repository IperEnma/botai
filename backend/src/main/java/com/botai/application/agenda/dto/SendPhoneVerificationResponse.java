package com.botai.application.agenda.dto;

public record SendPhoneVerificationResponse(
        boolean sent,
        String message,
        /** Solo en dev cuando falla WhatsApp y dev-echo está activo. */
        String devCodeEcho
) {}

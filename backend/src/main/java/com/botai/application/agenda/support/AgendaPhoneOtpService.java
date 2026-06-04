package com.botai.application.agenda.support;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;

/**
 * Genera y valida códigos OTP numéricos para verificar titularidad del teléfono (p. ej. consulta de reservas).
 */
@Service
public class AgendaPhoneOtpService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final int codeLength;
    private final long ttlMillis;

    public AgendaPhoneOtpService(
            @Value("${agenda.phone.verification.code-length:6}") int codeLength,
            @Value("${agenda.phone.verification.ttl-minutes:10}") int ttlMinutes) {
        this.codeLength = Math.max(4, Math.min(codeLength, 8));
        this.ttlMillis = Math.max(1, ttlMinutes) * 60_000L;
    }

    public String generateCode() {
        int bound = (int) Math.pow(10, codeLength);
        int min = bound / 10;
        int value = min + RANDOM.nextInt(bound - min);
        return String.valueOf(value);
    }

    public long expiryEpochMillis() {
        return Instant.now().toEpochMilli() + ttlMillis;
    }

    public boolean isExpired(long expiresAtEpochMillis) {
        return Instant.now().toEpochMilli() > expiresAtEpochMillis;
    }

    public boolean matches(String expectedCode, String userInput) {
        if (expectedCode == null || userInput == null) {
            return false;
        }
        String parsed = parseCode(userInput);
        return parsed != null && expectedCode.equals(parsed);
    }

    public static String parseCode(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String digits = raw.replaceAll("\\D", "");
        if (digits.length() >= 4 && digits.length() <= 8) {
            return digits;
        }
        return null;
    }
}

package com.botai.application.agenda.support;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * Hash irreversible de valores sensibles (OTP, tokens, teléfono) con pepper de configuración.
 */
@Component
public class AgendaSecurityHasher {

    static final String DEV_PEPPER = "dev-local-pepper-change-me";

    private final String pepper;

    public AgendaSecurityHasher(
            @Value("${agenda.phone.verification.hash-pepper:" + DEV_PEPPER + "}") String pepper) {
        this.pepper = pepper == null || pepper.isBlank() ? DEV_PEPPER : pepper.trim();
    }

    public String hash(String value) {
        if (value == null) {
            return hashInternal("");
        }
        return hashInternal(value);
    }

    public String phoneKey(String tenantId, String phoneNormalized) {
        return hash(tenantId + "|" + phoneNormalized);
    }

    public boolean matches(String raw, String storedHash) {
        if (storedHash == null || storedHash.isBlank()) {
            return false;
        }
        return storedHash.equals(hash(raw));
    }

    public boolean isDevPepper() {
        return DEV_PEPPER.equals(pepper);
    }

    public String pepperForDiagnostics() {
        return isDevPepper() ? "dev-default" : "configured";
    }

    private String hashInternal(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(pepper.getBytes(StandardCharsets.UTF_8));
            digest.update((byte) ':');
            digest.update(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest.digest());
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 no disponible", e);
        }
    }
}

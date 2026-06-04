package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * OTP para confirmar identidad al <strong>reservar</strong> (web pública). No aplica a consultas desde WhatsApp.
 */
@Service
public class AgendaPhoneVerificationService {

    private record PendingOtp(String code, long expiresAtEpochMs) {}

    private record VerificationGrant(String tenantId, String phoneNormalized, long expiresAtEpochMs) {}

    private final AgendaPhoneOtpService otpService;
    private final PhoneVerificationDeliveryPort deliveryPort;
    private final boolean enabled;
    private final boolean devEchoCodeInResponse;
    private final Map<String, PendingOtp> pendingByKey = new ConcurrentHashMap<>();
    private final Map<String, VerificationGrant> grantsByToken = new ConcurrentHashMap<>();

    public AgendaPhoneVerificationService(
            AgendaPhoneOtpService otpService,
            PhoneVerificationDeliveryPort deliveryPort,
            @Value("${agenda.phone.verification.enabled:true}") boolean enabled,
            @Value("${agenda.phone.verification.dev-echo-in-chat:false}") boolean devEchoCodeInResponse) {
        this.otpService = otpService;
        this.deliveryPort = deliveryPort;
        this.enabled = enabled;
        this.devEchoCodeInResponse = devEchoCodeInResponse;
    }

    public SendResult sendCode(String tenantId, String phoneNormalized) {
        if (!enabled) {
            String token = issueGrantWithoutOtp(tenantId, phoneNormalized);
            return new SendResult(true, null, token);
        }
        String code = otpService.generateCode();
        long expires = otpService.expiryEpochMillis();
        pendingByKey.put(key(tenantId, phoneNormalized), new PendingOtp(code, expires));

        boolean delivered = deliveryPort.sendVerificationCode(tenantId, phoneNormalized, code);
        String devCode = devEchoCodeInResponse && !delivered ? code : null;
        return new SendResult(delivered, devCode, null);
    }

    public String verifyAndIssueToken(String tenantId, String phoneNormalized, String userCode) {
        if (!enabled) {
            return issueGrantWithoutOtp(tenantId, phoneNormalized);
        }
        PendingOtp pending = pendingByKey.get(key(tenantId, phoneNormalized));
        if (pending == null) {
            throw new IllegalArgumentException("No hay código pendiente para este teléfono. Solicitá uno nuevo.");
        }
        if (otpService.isExpired(pending.expiresAtEpochMs())) {
            pendingByKey.remove(key(tenantId, phoneNormalized));
            throw new IllegalArgumentException("El código expiró. Solicitá uno nuevo.");
        }
        if (!otpService.matches(pending.code(), userCode)) {
            throw new IllegalArgumentException("Código incorrecto.");
        }
        pendingByKey.remove(key(tenantId, phoneNormalized));
        return issueGrant(tenantId, phoneNormalized);
    }

    public void assertValidToken(String tenantId, String phoneNormalized, String token) {
        if (!enabled) {
            return;
        }
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Verificá tu teléfono con el código de WhatsApp antes de reservar.");
        }
        VerificationGrant grant = grantsByToken.get(token.trim());
        if (grant == null) {
            throw new IllegalArgumentException("Verificación de teléfono inválida o expirada.");
        }
        if (otpService.isExpired(grant.expiresAtEpochMs())) {
            grantsByToken.remove(token.trim());
            throw new IllegalArgumentException("Verificación de teléfono expirada. Solicitá un código nuevo.");
        }
        if (!grant.tenantId().equals(tenantId)
            || !AgendaPhoneNormalizer.phonesMatch(grant.phoneNormalized(), phoneNormalized)) {
            throw new IllegalArgumentException("El código no corresponde a este teléfono.");
        }
        grantsByToken.remove(token.trim());
    }

    private String issueGrantWithoutOtp(String tenantId, String phoneNormalized) {
        return issueGrant(tenantId, phoneNormalized);
    }

    private String issueGrant(String tenantId, String phoneNormalized) {
        String token = UUID.randomUUID().toString();
        long expires = otpService.expiryEpochMillis();
        grantsByToken.put(token, new VerificationGrant(tenantId, phoneNormalized, expires));
        return token;
    }

    private static String key(String tenantId, String phone) {
        return tenantId + "|" + phone;
    }

    public record SendResult(boolean delivered, String devCodeEcho, String immediateTokenWhenDisabled) {}
}

package com.botai.application.agenda.support;

import com.botai.domain.agenda.service.PhoneVerificationDeliveryPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sesión de cliente en agenda pública: teléfono verificado por OTP (WhatsApp).
 * El token dura unos minutos y sirve para ver reservas y crear turnos sin repetir OTP.
 */
@Service
public class AgendaPublicClientSessionService {

    public static final String SESSION_HEADER = "X-Agenda-Client-Session";

    private record PendingOtp(String code, long expiresAtEpochMs) {}

    public record ClientSession(
            String tenantId,
            UUID userId,
            String phoneNormalized,
            long expiresAtEpochMs
    ) {}

    private final AgendaPhoneOtpService otpService;
    private final PhoneVerificationDeliveryPort deliveryPort;
    private final boolean enabled;
    private final boolean devEchoCodeInResponse;
    private final long sessionTtlMillis;
    private final Map<String, PendingOtp> pendingByKey = new ConcurrentHashMap<>();
    private final Map<String, ClientSession> sessionsByToken = new ConcurrentHashMap<>();

    public AgendaPublicClientSessionService(
            AgendaPhoneOtpService otpService,
            PhoneVerificationDeliveryPort deliveryPort,
            @Value("${agenda.phone.verification.enabled:true}") boolean enabled,
            @Value("${agenda.phone.verification.dev-echo-in-chat:false}") boolean devEchoCodeInResponse,
            @Value("${agenda.phone.verification.session-minutes:15}") int sessionMinutes) {
        this.otpService = otpService;
        this.deliveryPort = deliveryPort;
        this.enabled = enabled;
        this.devEchoCodeInResponse = devEchoCodeInResponse;
        this.sessionTtlMillis = Math.max(1, sessionMinutes) * 60L * 1000L;
    }

    public SendResult sendCode(String tenantId, String phoneNormalized) {
        if (!enabled) {
            return new SendResult(true, null);
        }
        String code = otpService.generateCode();
        long expires = otpService.expiryEpochMillis();
        pendingByKey.put(key(tenantId, phoneNormalized), new PendingOtp(code, expires));
        boolean delivered = deliveryPort.sendVerificationCode(tenantId, phoneNormalized, code);
        String devCode = devEchoCodeInResponse && !delivered ? code : null;
        return new SendResult(delivered, devCode);
    }

    public String issueSessionToken(String tenantId, UUID userId, String phoneNormalized) {
        String token = UUID.randomUUID().toString();
        long expires = System.currentTimeMillis() + sessionTtlMillis;
        sessionsByToken.put(token, new ClientSession(tenantId, userId, phoneNormalized, expires));
        return token;
    }

    public ClientSession requireSession(String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Iniciá sesión con tu teléfono y el código de WhatsApp.");
        }
        ClientSession session = sessionsByToken.get(token.trim());
        if (session == null) {
            throw new IllegalArgumentException("Sesión inválida o expirada. Verificá tu teléfono de nuevo.");
        }
        if (isExpired(session.expiresAtEpochMs())) {
            sessionsByToken.remove(token.trim());
            throw new IllegalArgumentException("Sesión expirada. Verificá tu teléfono de nuevo.");
        }
        return session;
    }

    public ClientSession requireSessionForTenant(String token, String tenantId) {
        ClientSession session = requireSession(token);
        if (!session.tenantId().equals(tenantId)) {
            throw new IllegalArgumentException("Sesión no válida para este negocio.");
        }
        return session;
    }

    public void verifyOtpCode(String tenantId, String phoneNormalized, String userCode) {
        if (!enabled) {
            return;
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
    }

    public ClientSession openSessionWithoutOtp(String tenantId, UUID userId, String phoneNormalized) {
        String token = issueSessionToken(tenantId, userId, phoneNormalized);
        return requireSession(token);
    }

    private static boolean isExpired(long expiresAtEpochMs) {
        return System.currentTimeMillis() > expiresAtEpochMs;
    }

    private static String key(String tenantId, String phone) {
        return tenantId + "|" + phone;
    }

    public record SendResult(boolean delivered, String devCodeEcho) {}
}

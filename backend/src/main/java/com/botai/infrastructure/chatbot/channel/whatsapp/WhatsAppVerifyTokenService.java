package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.infrastructure.chatbot.config.BotWhatsAppConfig;
import com.botai.infrastructure.chatbot.persistence.jpa.BotJpaRepository;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * Verify token derivado por bot (HMAC). No se persiste en BD: solo un secreto en config del servidor.
 * Formato expuesto a Meta: {@code {botId}.{firma-url-safe}}.
 */
@Service
public class WhatsAppVerifyTokenService {

    private static final String HMAC_ALG = "HmacSHA256";
    private static final String PAYLOAD_PREFIX = "wa-verify:";

    private final BotJpaRepository botRepository;
    private final BotWhatsAppConfig whatsAppConfig;

    public WhatsAppVerifyTokenService(BotJpaRepository botRepository, BotWhatsAppConfig whatsAppConfig) {
        this.botRepository = botRepository;
        this.whatsAppConfig = whatsAppConfig;
    }

    /** Token que el tenant pega en Meta (derivado, no almacenado). */
    public String tokenForBot(long botId) {
        byte[] mac = hmac((PAYLOAD_PREFIX + botId).getBytes(StandardCharsets.UTF_8));
        return botId + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(mac);
    }

    public boolean accepts(String token) {
        if (token == null || token.isBlank()) {
            return false;
        }
        String legacyGlobal = whatsAppConfig.getVerifyToken();
        if (legacyGlobal != null && !legacyGlobal.isBlank() && constantTimeEquals(legacyGlobal, token)) {
            return true;
        }
        if (acceptsDerived(token)) {
            return true;
        }
        // Transición: tokens viejos guardados en claro en BD (no se escriben más).
        return botRepository.existsByWhatsappVerifyToken(token);
    }

    private boolean acceptsDerived(String token) {
        int dot = token.indexOf('.');
        if (dot <= 0 || dot == token.length() - 1) {
            return false;
        }
        try {
            long botId = Long.parseLong(token.substring(0, dot));
            if (!botRepository.existsById(botId)) {
                return false;
            }
            return constantTimeEquals(tokenForBot(botId), token);
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private byte[] hmac(byte[] payload) {
        String secret = whatsAppConfig.getVerifySecret();
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException(
                    "bot.whatsapp.verify-secret (BOT_WHATSAPP_VERIFY_SECRET) es obligatorio");
        }
        try {
            Mac mac = Mac.getInstance(HMAC_ALG);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALG));
            return mac.doFinal(payload);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("No se pudo calcular HMAC del verify token", e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        return MessageDigest.isEqual(
                a.getBytes(StandardCharsets.UTF_8),
                b.getBytes(StandardCharsets.UTF_8));
    }
}

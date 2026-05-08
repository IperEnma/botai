package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.infrastructure.chatbot.persistence.entity.BotEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.BotJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import com.botai.infrastructure.chatbot.http.HttpMessageConvertersUtf8;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Optional;

/**
 * Cliente para enviar mensajes con WhatsApp Cloud API (Meta Graph API).
 * POST https://graph.facebook.com/v18.0/{phone_number_id}/messages
 *
 * La configuración se obtiene solo de la base de datos por tenant.
 */
@Component
public class WhatsAppCloudApiClient {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppCloudApiClient.class);
    private static final String GRAPH_API_URL = "https://graph.facebook.com/v18.0";
    private static final int MAX_BODY_LENGTH = 4096;
    private static final ObjectMapper JSON = new ObjectMapper();

    private final RestTemplate restTemplate = createUtf8RestTemplate();
    private final BotJpaRepository botRepository;

    public WhatsAppCloudApiClient(BotJpaRepository botRepository) {
        this.botRepository = botRepository;
    }

    /**
     * Fuerza UTF-8 en el cuerpo JSON hacia Graph API y evita ambigüedad de charset en {@link RestTemplate}.
     */
    private static RestTemplate createUtf8RestTemplate() {
        RestTemplate rt = new RestTemplate();
        HttpMessageConvertersUtf8.applyTo(rt.getMessageConverters());
        return rt;
    }

    /**
     * Envía un mensaje de texto usando la configuración del tenant (solo desde BD).
     *
     * @return {@code true} si Meta respondió 2xx; {@code false} si no se envió o hubo error (permisos, token, etc.)
     */
    public boolean sendText(String tenantId, String toPhoneNumber, String body) {
        log.info("[WA-API] sendText() llamado: tenant={}, to={}", tenantId, toPhoneNumber);
        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[WA-API] tenantId ausente, no se puede enviar");
            return false;
        }
        Optional<BotEntity> botOpt = botRepository.findByTenantId(tenantId);
        if (botOpt.isEmpty()) {
            log.warn("[WA-API] No hay bot configurado para tenant '{}', no se envía", tenantId);
            return false;
        }

        BotEntity bot = botOpt.get();
        String accessToken = bot.getWhatsappAccessToken();
        String phoneNumberId = bot.getWhatsappPhoneNumberId();
        log.info("[WA-API] Usando config del bot '{}' (tenant={})", bot.getName(), tenantId);

        return doSendText(accessToken, phoneNumberId, toPhoneNumber, body);
    }

    private boolean doSendText(String accessToken, String phoneNumberId, String toPhoneNumber, String body) {
        if (accessToken == null || accessToken.isBlank() || phoneNumberId == null || phoneNumberId.isBlank()) {
            log.warn("[WA-API] Token o phoneNumberId no configurado, no se envía");
            return false;
        }
        
        String safeBody = body != null && body.length() > MAX_BODY_LENGTH
            ? body.substring(0, MAX_BODY_LENGTH - 3) + "..."
            : (body != null ? body : "");
        String to = toPhoneNumber != null ? toPhoneNumber.replace("+", "").replaceAll("\\s", "") : "";
        if (to.isBlank()) {
            log.warn("[WA-API] Número destino vacío, no se envía");
            return false;
        }

        String url = GRAPH_API_URL + "/" + phoneNumberId + "/messages";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(new MediaType("application", "json", StandardCharsets.UTF_8));
        headers.setBearerAuth(accessToken);

        Map<String, Object> request = Map.of(
            "messaging_product", "whatsapp",
            "recipient_type", "individual",
            "to", to,
            "type", "text",
            "text", Map.of("body", safeBody)
        );

        log.info("[WA-API] Enviando POST a Meta: to={}, body='{}'", to, safeBody.length() > 100 ? safeBody.substring(0,100)+"..." : safeBody);

        final String jsonPayload;
        try {
            jsonPayload = JSON.writeValueAsString(request);
        } catch (Exception e) {
            log.error("[WA-API] No se pudo serializar JSON UTF-8: {}", e.getMessage());
            return false;
        }
        HttpEntity<String> entity = new HttpEntity<>(jsonPayload, headers);
        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
            boolean ok = response.getStatusCode().is2xxSuccessful();
            log.info("[WA-API] Respuesta de Meta: status={}", response.getStatusCode());
            return ok;
        } catch (Exception e) {
            log.error("[WA-API] ERROR enviando a Meta: {}", e.getMessage());
            return false;
        }
    }
}

package com.botai.chatbot.infrastructure.channel.whatsapp;

import com.botai.chatbot.infrastructure.persistence.entity.BotEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.BotJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

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

    private final RestTemplate restTemplate = new RestTemplate();
    private final BotJpaRepository botRepository;

    public WhatsAppCloudApiClient(BotJpaRepository botRepository) {
        this.botRepository = botRepository;
    }

    /**
     * Envía un mensaje de texto usando la configuración del tenant (solo desde BD).
     */
    public void sendText(String tenantId, String toPhoneNumber, String body) {
        log.info("[WA-API] sendText() llamado: tenant={}, to={}", tenantId, toPhoneNumber);
        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[WA-API] tenantId ausente, no se puede enviar");
            return;
        }
        Optional<BotEntity> botOpt = botRepository.findByTenantId(tenantId);
        if (botOpt.isEmpty()) {
            log.warn("[WA-API] No hay bot configurado para tenant '{}', no se envía", tenantId);
            return;
        }

        BotEntity bot = botOpt.get();
        String accessToken = bot.getWhatsappAccessToken();
        String phoneNumberId = bot.getWhatsappPhoneNumberId();
        log.info("[WA-API] Usando config del bot '{}' (tenant={})", bot.getName(), tenantId);

        doSendText(accessToken, phoneNumberId, toPhoneNumber, body);
    }

    private void doSendText(String accessToken, String phoneNumberId, String toPhoneNumber, String body) {
        if (accessToken == null || accessToken.isBlank() || phoneNumberId == null || phoneNumberId.isBlank()) {
            log.warn("[WA-API] Token o phoneNumberId no configurado, no se envía");
            return;
        }
        
        String safeBody = body != null && body.length() > MAX_BODY_LENGTH
            ? body.substring(0, MAX_BODY_LENGTH - 3) + "..."
            : (body != null ? body : "");
        String to = toPhoneNumber != null ? toPhoneNumber.replace("+", "").replaceAll("\\s", "") : "";
        if (to.isBlank()) {
            log.warn("[WA-API] Número destino vacío, no se envía");
            return;
        }

        String url = GRAPH_API_URL + "/" + phoneNumberId + "/messages";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(accessToken);

        Map<String, Object> request = Map.of(
            "messaging_product", "whatsapp",
            "recipient_type", "individual",
            "to", to,
            "type", "text",
            "text", Map.of("body", safeBody)
        );

        log.info("[WA-API] Enviando POST a Meta: to={}, body='{}'", to, safeBody.length() > 100 ? safeBody.substring(0,100)+"..." : safeBody);
        
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
            log.info("[WA-API] Respuesta de Meta: status={}", response.getStatusCode());
        } catch (Exception e) {
            log.error("[WA-API] ERROR enviando a Meta: {}", e.getMessage());
        }
    }
}

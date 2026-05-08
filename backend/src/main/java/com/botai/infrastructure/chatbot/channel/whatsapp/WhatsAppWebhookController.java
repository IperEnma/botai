package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.infrastructure.chatbot.channel.MessageBufferService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Webhook de WhatsApp Cloud API (Meta).
 * GET: verificación (hub.mode, hub.verify_token, hub.challenge).
 * POST: notificaciones (mensajes entrantes y estados); solo se responde a mensajes de texto.
 */
@RestController
@RequestMapping("/api/v1/webhook/whatsapp")
public class WhatsAppWebhookController {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppWebhookController.class);

    private final WhatsAppAdapter adapter;
    private final WhatsAppProperties properties;
    private final MessageBufferService bufferService;
    private final ObjectMapper objectMapper;

    public WhatsAppWebhookController(WhatsAppAdapter adapter,
                                     WhatsAppProperties properties,
                                     MessageBufferService bufferService,
                                     ObjectMapper objectMapper) {
        this.adapter = adapter;
        this.properties = properties;
        this.bufferService = bufferService;
        this.objectMapper = objectMapper;
    }

    /**
     * Verificación del webhook: Meta envía GET con hub.mode, hub.verify_token, hub.challenge.
     * Si verify_token coincide con la config, devolver el challenge.
     */
    @GetMapping
    public ResponseEntity<String> verifyWebhook(
            @RequestParam(name = "hub.mode", required = false) String mode,
            @RequestParam(name = "hub.verify_token", required = false) String token,
            @RequestParam(name = "hub.challenge", required = false) String challenge) {
        if ("subscribe".equals(mode) && token != null && token.equals(properties.getVerifyToken())) {
            return ResponseEntity.ok(challenge != null ? challenge : "");
        }
        return ResponseEntity.status(403).body("Invalid verify token");
    }

    /**
     * Notificaciones: mensajes entrantes (messages) y estados (statuses).
     * Decodifica el cuerpo como UTF-8 y parsea JSON; el log usa JSON serializado (escapes \\u) para que en consolas
     * no-UTF-8 se vea legible el texto con tildes.
     */
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Void> handleWebhook(@RequestBody byte[] body) throws IOException {
        log.info("========== [WEBHOOK] POST RECIBIDO ==========");
        Map<String, Object> payload = objectMapper.readValue(
            new String(body, StandardCharsets.UTF_8),
            new TypeReference<Map<String, Object>>() {});
        log.info("[WEBHOOK] Payload JSON: {}", objectMapper.writeValueAsString(payload));
        
        InboundMessage inbound = adapter.toInboundMessage(payload);
        log.info("[WEBHOOK] Mensaje parseado: userId={}, text='{}'", inbound.getUserId(), inbound.getText());
        
        if (inbound.getText() == null || inbound.getText().isBlank()) {
            log.info("[WEBHOOK] Texto vacio -> IGNORANDO (status update o mensaje no-texto)");
            log.info("========== [WEBHOOK] FIN (ignorado) ==========");
            return ResponseEntity.ok().build();
        }
        
        log.info("[WEBHOOK] Enviando al buffer...");
        bufferService.bufferAndProcess(inbound, adapter::send);
        log.info("========== [WEBHOOK] FIN (procesando) ==========");
        return ResponseEntity.ok().build();
    }
}

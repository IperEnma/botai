package com.botai.infrastructure.chatbot.channel.whatsapp;

import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.infrastructure.chatbot.channel.MessageBufferService;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppLogRedaction;
import com.botai.infrastructure.chatbot.channel.whatsapp.WhatsAppVerifyTokenService;
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
    private final MessageBufferService bufferService;
    private final ObjectMapper objectMapper;
    private final WhatsAppVerifyTokenService verifyTokenService;

    public WhatsAppWebhookController(WhatsAppAdapter adapter,
                                     MessageBufferService bufferService,
                                     ObjectMapper objectMapper,
                                     WhatsAppVerifyTokenService verifyTokenService) {
        this.adapter = adapter;
        this.bufferService = bufferService;
        this.objectMapper = objectMapper;
        this.verifyTokenService = verifyTokenService;
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
        if ("subscribe".equals(mode) && verifyTokenService.accepts(token)) {
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
        Map<String, Object> payload = objectMapper.readValue(
            new String(body, StandardCharsets.UTF_8),
            new TypeReference<Map<String, Object>>() {});

        if (log.isDebugEnabled()) {
            log.debug("[WEBHOOK] Payload completo: {}", objectMapper.writeValueAsString(payload));
        }
        log.info("[WEBHOOK] POST recibido: {}", WhatsAppLogRedaction.summarizeWebhook(payload));

        InboundMessage inbound = adapter.toInboundMessage(payload);
        String preview = WhatsAppLogRedaction.truncateText(inbound.getText(), 80);
        log.info("[WEBHOOK] Parseado: user={}, text='{}'",
                WhatsAppLogRedaction.maskPhone(inbound.getUserId()), preview);

        if (inbound.getText() == null || inbound.getText().isBlank()) {
            log.debug("[WEBHOOK] Texto vacío -> ignorado (status update o mensaje no-texto)");
            return ResponseEntity.ok().build();
        }

        bufferService.bufferAndProcess(inbound, adapter::send);
        return ResponseEntity.ok().build();
    }
}

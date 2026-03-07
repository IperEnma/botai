package com.botai.chatbot.infrastructure.channel.whatsapp;

import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.infrastructure.channel.MessageBufferService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

    public WhatsAppWebhookController(WhatsAppAdapter adapter,
                                     WhatsAppProperties properties,
                                     MessageBufferService bufferService) {
        this.adapter = adapter;
        this.properties = properties;
        this.bufferService = bufferService;
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
     * Solo procesamos cuando hay un mensaje de texto del usuario; ignoramos statuses.
     */
    @PostMapping
    public ResponseEntity<Void> handleWebhook(@RequestBody Map<String, Object> payload) {
        log.info("========== [WEBHOOK] POST RECIBIDO ==========");
        log.info("[WEBHOOK] Payload completo: {}", payload);
        
        InboundMessage inbound = adapter.toInboundMessage(payload);
        log.info("[WEBHOOK] Mensaje parseado: userId={}, text='{}'", inbound.getUserId(), inbound.getText());
        
        if (inbound.getText() == null || inbound.getText().isBlank()) {
            log.info("[WEBHOOK] Texto vacío -> IGNORANDO (status update o mensaje no-texto)");
            log.info("========== [WEBHOOK] FIN (ignorado) ==========");
            return ResponseEntity.ok().build();
        }
        
        log.info("[WEBHOOK] Enviando al buffer...");
        bufferService.bufferAndProcess(inbound, adapter::send);
        log.info("========== [WEBHOOK] FIN (procesando) ==========");
        return ResponseEntity.ok().build();
    }
}

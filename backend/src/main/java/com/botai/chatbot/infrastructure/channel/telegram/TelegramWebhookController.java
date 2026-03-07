package com.botai.chatbot.infrastructure.channel.telegram;

import com.botai.chatbot.application.dto.ProcessMessageResult;
import com.botai.chatbot.application.usecase.ProcessInboundMessageUseCase;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Webhook endpoint for Telegram. Receives update, converts via TelegramAdapter, processes, sends reply.
 */
@RestController
@RequestMapping("/api/v1/webhook/telegram")
public class TelegramWebhookController {

    private final TelegramAdapter adapter;
    private final ProcessInboundMessageUseCase processInboundMessageUseCase;

    public TelegramWebhookController(TelegramAdapter adapter,
                                     ProcessInboundMessageUseCase processInboundMessageUseCase) {
        this.adapter = adapter;
        this.processInboundMessageUseCase = processInboundMessageUseCase;
    }

    @PostMapping
    public ResponseEntity<Void> handleWebhook(@RequestBody Map<String, Object> payload) {
        InboundMessage inbound = adapter.toInboundMessage(payload);
        ProcessMessageResult result = processInboundMessageUseCase.execute(inbound);
        OutboundMessage out = result.outboundMessage();
        if (out != null) {
            adapter.send(out);
        }
        return ResponseEntity.ok().build();
    }
}

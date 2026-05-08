package com.botai.infrastructure.chatbot.channel.web;

import com.botai.application.chatbot.dto.ProcessMessageResult;
import com.botai.application.chatbot.usecase.ProcessInboundMessageUseCase;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.infrastructure.chatbot.channel.ChannelAdapter;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Web channel: REST API. Receives JSON body as "raw" payload, uses a generic mapping to InboundMessage,
 * processes through core, returns OutboundMessage as JSON.
 */
@RestController
@RequestMapping("${bot.channels.web.base-path:/api/v1/webhook}")
public class WebChannelController {

    private static final String WEB_CHANNEL_ID = "web";

    private final ProcessInboundMessageUseCase processInboundMessageUseCase;

    public WebChannelController(ProcessInboundMessageUseCase processInboundMessageUseCase) {
        this.processInboundMessageUseCase = processInboundMessageUseCase;
    }

    @PostMapping("/message")
    public ResponseEntity<WebOutboundDto> handleMessage(@RequestBody Map<String, Object> body) {
        InboundMessage inbound = toInboundMessage(body);
        ProcessMessageResult result = processInboundMessageUseCase.execute(inbound);
        OutboundMessage out = result.outboundMessage();
        return ResponseEntity.ok(toDto(out, result.intentSource()));
    }

    private InboundMessage toInboundMessage(Map<String, Object> body) {
        String userId = (String) body.getOrDefault("userId", "web-user");
        String conversationId = (String) body.getOrDefault("conversationId", userId + "@web");
        String text = (String) body.getOrDefault("text", "");
        @SuppressWarnings("unchecked")
        Map<String, Object> metadata = (Map<String, Object>) body.getOrDefault("metadata", Map.of());
        return InboundMessage.builder()
            .channelId(WEB_CHANNEL_ID)
            .userId(userId)
            .conversationId(conversationId)
            .text(text)
            .metadata(metadata)
            .build();
    }

    private WebOutboundDto toDto(OutboundMessage m, String intentSource) {
        List<WebActionDto> actions = m.getActions().stream()
            .map(a -> new WebActionDto(a.id(), a.label(), a.type()))
            .collect(Collectors.toList());
        return new WebOutboundDto(m.getText(), m.getOptions(), actions, m.getConversationId(), intentSource);
    }

    public record WebOutboundDto(
        String text,
        List<String> options,
        List<WebActionDto> actions,
        String conversationId,
        String intentSource
    ) {}

    public record WebActionDto(String id, String label, String type) {}
}

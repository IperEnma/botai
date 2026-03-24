package com.botai.chatbot.infrastructure.api;

import com.botai.chatbot.application.service.conversation.ai.RagLlmChatService;
import com.botai.chatbot.domain.ConversationContextKeys;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Diagnóstico: comparar respuesta del LLM sin fragmentos RAG (mismas tools + memoria por conversación).
 */
@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatDiagnosticController {

    private final RagLlmChatService ragLlmChatService;

    public ChatDiagnosticController(RagLlmChatService ragLlmChatService) {
        this.ragLlmChatService = ragLlmChatService;
    }

    /**
     * POST JSON: {@code { "tenantId": "...", "message": "...", "conversationId": "opcional" }}.
     * Sin clasificación de intención (null): solo prompt mínimo + tools; no fragmentos de conocimiento.
     */
    @PostMapping("/no-rag")
    public ResponseEntity<Map<String, String>> chatNoRag(@RequestBody NoRagRequest body) {
        if (body == null || body.tenantId() == null || body.tenantId().isBlank()
            || body.message() == null || body.message().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "tenantId y message son obligatorios"));
        }
        String convId = body.conversationId() != null && !body.conversationId().isBlank()
            ? body.conversationId()
            : "diag-no-rag@" + body.tenantId();
        InboundMessage inbound = InboundMessage.builder()
            .channelId("diagnostic")
            .userId("user-no-rag")
            .conversationId(convId)
            .text(body.message())
            .metadata(Map.of("tenantId", body.tenantId()))
            .build();
        ConversationState state = ConversationState.builder()
            .conversationId(convId)
            .userId("user-no-rag")
            .channelId("diagnostic")
            .context(Map.of(ConversationContextKeys.TENANT_ID, body.tenantId()))
            .build();
        OutboundMessage out = ragLlmChatService.generateResponseNoRag(inbound, state, null);
        String text = out.getText() != null ? out.getText() : "";
        return ResponseEntity.ok(Map.of("reply", text));
    }

    public record NoRagRequest(String tenantId, String message, String conversationId) {}
}

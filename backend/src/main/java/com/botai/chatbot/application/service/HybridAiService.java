package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.*;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.domain.service.LanguageModel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 * Hybrid AI: builds context, calls LLM, validates response (no inventing information).
 * Core does not know which LLM implementation is used.
 */
public class HybridAiService {

    private static final Logger log = LoggerFactory.getLogger(HybridAiService.class);
    private static final int MAX_TOKENS = 512;

    private final LanguageModel languageModel;
    private final ConversationRepository conversationRepository;
    private final AiContextBuilder contextBuilder;
    private final ResponseValidator responseValidator;
    private final MessageHistoryService messageHistoryService;

    public HybridAiService(LanguageModel languageModel,
                           ConversationRepository conversationRepository,
                           AiContextBuilder contextBuilder,
                           ResponseValidator responseValidator,
                           MessageHistoryService messageHistoryService) {
        this.languageModel = languageModel;
        this.conversationRepository = conversationRepository;
        this.contextBuilder = contextBuilder;
        this.responseValidator = responseValidator;
        this.messageHistoryService = messageHistoryService;
    }

    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state) {
        String conversationId = inbound.getConversationId();
        String userText = inbound.getText();
        Object t = inbound.getMetadata() != null ? inbound.getMetadata().get("tenantId") : null;
        String tenantId = t != null ? t.toString().strip() : null;
        if (tenantId != null && tenantId.isEmpty()) tenantId = null;

        messageHistoryService.saveUserMessage(conversationId, userText);

        List<String> history = messageHistoryService.getHistory(conversationId);
        List<String> systemPrompt = contextBuilder.buildSystemPrompt(state, userText);

        LlmRequest request = new LlmRequest(userText, systemPrompt, history, MAX_TOKENS);
        LlmResponse response = languageModel.generate(request);

        if (!response.isSuccess()) {
            String llmError = response.getErrorMessage() != null ? response.getErrorMessage() : "unknown";
            log.warn("[AI] LLM falló para conversación {}: {}. Revisa que Ollama esté corriendo ({}).",
                conversationId, llmError, "ej. ollama serve o docker con ollama");
            String errorMsg = "Estamos procesando tu consulta. Por favor, intenta de nuevo en un momento.";
            messageHistoryService.saveAssistantMessage(conversationId, errorMsg);
            return OutboundMessage.builder()
                .text(errorMsg)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        }

        String rawText = response.getText();
        String safeText = responseValidator.validateAndSanitize(rawText);

        messageHistoryService.saveAssistantMessage(conversationId, safeText);

        return OutboundMessage.builder()
            .text(safeText)
            .conversationId(conversationId)
            .tenantId(tenantId)
            .build();
    }

    /**
     * Builds system prompt lines (instructions + optional RAG context from user query).
     */
    public interface AiContextBuilder {
        List<String> buildSystemPrompt(ConversationState state, String userMessage);
    }

    /**
     * Validates/sanitizes LLM output. Must not invent information.
     */
    public interface ResponseValidator {
        String validateAndSanitize(String rawResponse);
    }
}

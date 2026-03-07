package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.service.HybridAiService;
import com.botai.chatbot.domain.model.ConversationState;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Builds system prompt for the LLM (sin RAG). Usado si no se usa RagAiContextBuilder.
 */
@Component
public class DefaultAiContextBuilder implements HybridAiService.AiContextBuilder {

    @Override
    public List<String> buildSystemPrompt(ConversationState state, String userMessage) {
        return List.of(
            "Eres un asistente útil y profesional.",
            "Basa tus respuestas en información del contexto o conocimiento general verificable.",
            "Incluye solo datos, precios y fechas que puedas confirmar como precisos.",
            "Ante información faltante, sugiere contactar al equipo para obtener detalles específicos.",
            "Mantén respuestas breves, claras y en tono profesional."
        );
    }
}

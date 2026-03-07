package com.botai.chatbot.infrastructure.ai;

import com.botai.chatbot.application.service.HybridAiService;
import com.botai.chatbot.application.service.KnowledgeService;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.KnowledgeChunk;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * RAG: construye el system prompt con fragmentos de conocimiento del tenant.
 * La identidad y tipo de negocio (ej. nombre, rubro) salen solo de la base de conocimiento, no están hardcodeados.
 */
@Component
@Primary
public class RagAiContextBuilder implements HybridAiService.AiContextBuilder {

    private static final int RAG_MAX_CHUNKS = 5;

    private final KnowledgeService knowledgeService;
    private final int maxChunks;

    public RagAiContextBuilder(KnowledgeService knowledgeService,
                               @Value("${bot.rag.max-chunks:5}") int maxChunks) {
        this.knowledgeService = knowledgeService;
        this.maxChunks = maxChunks > 0 ? maxChunks : RAG_MAX_CHUNKS;
    }

    @Override
    public List<String> buildSystemPrompt(ConversationState state, String userMessage) {
        List<String> lines = new ArrayList<>();

        lines.add("Eres el asistente virtual. Responde de forma amable y clara.");
        lines.add("Basa tus respuestas EXCLUSIVAMENTE en la información proporcionada a continuación (quién es el negocio, horarios, servicios, precios, etc.).");
        lines.add("Incluye solo precios, horarios y datos que aparezcan explícitamente en el contexto.");
        lines.add("Cuando la información solicitada esté fuera del contexto, indica que pueden obtener más detalles por teléfono o email.");
        lines.add("Mantén respuestas breves (1-3 párrafos) y en tono profesional.");

        List<KnowledgeChunk> chunks = knowledgeService.findRelevant(userMessage, maxChunks);
        if (!chunks.isEmpty()) {
            lines.add("");
            lines.add("--- Información proporcionada (usa solo esto para responder) ---");
            for (KnowledgeChunk c : chunks) {
                lines.add("[" + c.getTopic() + "] " + c.getContent());
            }
            lines.add("--- Fin de la información ---");
        }

        return lines;
    }
}

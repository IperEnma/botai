package com.botai.application.chatbot.service.inbound;

import com.botai.infrastructure.chatbot.persistence.entity.MessageEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.MessageJpaRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Persistencia de mensajes user/assistant por {@code conversationId} y {@code sessionId}.
 * <ul>
 *   <li><strong>Turnos con IA (ChatClient):</strong> ventana y guardado vía
 *       {@link org.springframework.ai.chat.memory.MessageWindowChatMemory} +
 *       {@link com.botai.infrastructure.chatbot.ai.memory.JpaChatMemoryRepository} (tabla {@code message})
 *       y {@link org.springframework.ai.chat.client.advisor.PromptChatMemoryAdvisor} inyecta MEMORY en el system.</li>
 *   <li><strong>Menú / FAQ / errores:</strong> este servicio ({@link #saveUserMessage} / {@link #saveAssistantMessage}).</li>
 * </ul>
 * {@link com.botai.application.chatbot.dto.ConversationIntentSource#historyManagedByAiLayer(String)} evita duplicar
 * guardado en {@link com.botai.application.chatbot.service.inbound.ConversationCore} cuando la IA ya persistió el turno.
 * Ventana IA: {@code bot.memory.max-history-turns} (≈ {@code 2 ×} turnos en mensajes).
 */
@Service
public class MessageHistoryService {

    private static final String ROLE_USER = "user";
    private static final String ROLE_ASSISTANT = "assistant";

    private final MessageJpaRepository messageRepository;
    private final int maxHistoryTurns;

    public MessageHistoryService(MessageJpaRepository messageRepository,
                                 @Value("${bot.memory.max-history-turns:10}") int maxHistoryTurns) {
        this.messageRepository = messageRepository;
        this.maxHistoryTurns = maxHistoryTurns;
    }

    /**
     * Save user message to history for the current chat session (solo ve el LLM mensajes de esta sesión).
     */
    public void saveUserMessage(String conversationId, String sessionId, String content) {
        saveMessage(conversationId, sessionId, ROLE_USER, content);
    }

    /**
     * Save assistant (bot) message to history for the current chat session.
     */
    public void saveAssistantMessage(String conversationId, String sessionId, String content) {
        saveMessage(conversationId, sessionId, ROLE_ASSISTANT, content);
    }

    private void saveMessage(String conversationId, String sessionId, String role, String content) {
        if (content == null || content.isBlank()) {
            return;
        }
        MessageEntity msg = new MessageEntity();
        msg.setConversationId(conversationId);
        if (sessionId != null && !sessionId.isBlank()) {
            msg.setSessionId(sessionId);
        }
        msg.setRole(role);
        msg.setContent(content);
        messageRepository.save(msg);
    }

    /**
     * Historial reciente solo de la sesión actual (para el LLM).
     */
    public List<String> getHistory(String conversationId, String sessionId) {
        List<MessageEntity> recent;
        if (sessionId != null && !sessionId.isBlank()) {
            recent = messageRepository.findRecentByConversationIdAndSessionId(
                conversationId, sessionId, PageRequest.of(0, maxHistoryTurns * 2));
        } else {
            recent = messageRepository.findRecentByConversationId(
                conversationId, PageRequest.of(0, maxHistoryTurns * 2));
        }
        
        if (recent.isEmpty()) {
            return Collections.emptyList();
        }

        List<String> history = new ArrayList<>();
        for (MessageEntity m : recent) {
            history.add(m.getRole() + ": " + m.getContent());
        }
        Collections.reverse(history);
        return history;
    }
}

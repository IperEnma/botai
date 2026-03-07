package com.botai.chatbot.application.service;

import com.botai.chatbot.infrastructure.persistence.entity.MessageEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.MessageJpaRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Manages conversation history (memory). Stores and retrieves messages.
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
     * Save user message to history.
     */
    public void saveUserMessage(String conversationId, String content) {
        saveMessage(conversationId, ROLE_USER, content);
    }

    /**
     * Save assistant (bot) message to history.
     */
    public void saveAssistantMessage(String conversationId, String content) {
        saveMessage(conversationId, ROLE_ASSISTANT, content);
    }

    private void saveMessage(String conversationId, String role, String content) {
        if (content == null || content.isBlank()) {
            return;
        }
        MessageEntity msg = new MessageEntity();
        msg.setConversationId(conversationId);
        msg.setRole(role);
        msg.setContent(content);
        messageRepository.save(msg);
    }

    /**
     * Get recent conversation history formatted for LLM context.
     * Returns list of strings like "user: mensaje" or "assistant: respuesta"
     */
    public List<String> getHistory(String conversationId) {
        List<MessageEntity> recent = messageRepository.findRecentByConversationId(
            conversationId, PageRequest.of(0, maxHistoryTurns * 2));
        
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

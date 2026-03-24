package com.botai.chatbot.infrastructure.ai.memory;

import com.botai.chatbot.infrastructure.persistence.entity.MessageEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.MessageJpaRepository;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.memory.ChatMemoryRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Persistencia de {@link org.springframework.ai.chat.memory.ChatMemory} sobre la tabla {@code message}
 * (misma fuente que {@link com.botai.chatbot.application.service.inbound.MessageHistoryService}).
 */
@Repository
public class JpaChatMemoryRepository implements ChatMemoryRepository {

    private final MessageJpaRepository messageRepository;

    public JpaChatMemoryRepository(MessageJpaRepository messageRepository) {
        this.messageRepository = messageRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> findConversationIds() {
        List<Object[]> rows = messageRepository.findDistinctConversationIdAndSessionId();
        Set<String> keys = new LinkedHashSet<>();
        for (Object[] row : rows) {
            if (row == null || row.length < 2) {
                continue;
            }
            String conv = row[0] != null ? row[0].toString() : "";
            String sess = row[1] != null ? row[1].toString() : null;
            if (!conv.isBlank()) {
                keys.add(ChatMemoryConversationIdCodec.encode(conv, sess));
            }
        }
        return new ArrayList<>(keys);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Message> findByConversationId(String conversationId) {
        ChatMemoryConversationIdCodec.Parts p = ChatMemoryConversationIdCodec.decode(conversationId);
        List<MessageEntity> rows = messageRepository.findForChatMemoryOrderByCreatedAt(
            p.conversationId(), p.sessionId());
        List<Message> out = new ArrayList<>(rows.size());
        for (MessageEntity e : rows) {
            String role = e.getRole();
            String content = e.getContent() != null ? e.getContent() : "";
            if ("user".equalsIgnoreCase(role)) {
                out.add(new UserMessage(content));
            } else if ("assistant".equalsIgnoreCase(role)) {
                out.add(new AssistantMessage(content));
            }
        }
        return out;
    }

    @Override
    @Transactional
    public void saveAll(String conversationId, List<Message> messages) {
        ChatMemoryConversationIdCodec.Parts p = ChatMemoryConversationIdCodec.decode(conversationId);
        messageRepository.deleteForChatMemory(p.conversationId(), p.sessionId());
        if (messages == null || messages.isEmpty()) {
            return;
        }
        for (Message m : messages) {
            if (m instanceof UserMessage um) {
                persist(p, "user", textOf(um));
            } else if (m instanceof AssistantMessage am) {
                persist(p, "assistant", textOf(am));
            }
        }
    }

    private static String textOf(Message m) {
        String t = m.getText();
        return t != null ? t : "";
    }

    private void persist(ChatMemoryConversationIdCodec.Parts p, String role, String content) {
        if (content == null || content.isBlank()) {
            return;
        }
        MessageEntity e = new MessageEntity();
        e.setConversationId(p.conversationId());
        e.setSessionId(p.sessionId());
        e.setRole(role);
        e.setContent(content);
        messageRepository.save(e);
    }

    @Override
    @Transactional
    public void deleteByConversationId(String conversationId) {
        ChatMemoryConversationIdCodec.Parts p = ChatMemoryConversationIdCodec.decode(conversationId);
        messageRepository.deleteForChatMemory(p.conversationId(), p.sessionId());
    }
}

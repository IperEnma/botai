package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.MessageEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageJpaRepository extends JpaRepository<MessageEntity, Long> {

    @Query("SELECT m FROM MessageEntity m WHERE m.conversationId = :convId ORDER BY m.createdAt DESC")
    List<MessageEntity> findRecentByConversationId(@Param("convId") String conversationId, Pageable pageable);

    @Query("SELECT m FROM MessageEntity m WHERE m.conversationId = :convId AND m.sessionId = :sessionId ORDER BY m.createdAt DESC")
    List<MessageEntity> findRecentByConversationIdAndSessionId(
        @Param("convId") String conversationId,
        @Param("sessionId") String sessionId,
        Pageable pageable);

    /** Historial completo en orden cronológico para {@link com.botai.infrastructure.chatbot.ai.memory.JpaChatMemoryRepository}. */
    @Query("SELECT m FROM MessageEntity m WHERE m.conversationId = :convId AND "
        + "((:sessionId IS NULL AND m.sessionId IS NULL) OR m.sessionId = :sessionId) "
        + "ORDER BY m.createdAt ASC, m.id ASC")
    List<MessageEntity> findForChatMemoryOrderByCreatedAt(
        @Param("convId") String conversationId,
        @Param("sessionId") String sessionId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM MessageEntity m WHERE m.conversationId = :convId AND "
        + "((:sessionId IS NULL AND m.sessionId IS NULL) OR m.sessionId = :sessionId)")
    void deleteForChatMemory(
        @Param("convId") String conversationId,
        @Param("sessionId") String sessionId);

    @Query("SELECT DISTINCT m.conversationId, m.sessionId FROM MessageEntity m")
    List<Object[]> findDistinctConversationIdAndSessionId();
}

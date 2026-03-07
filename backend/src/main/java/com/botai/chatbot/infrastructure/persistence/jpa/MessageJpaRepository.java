package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.MessageEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageJpaRepository extends JpaRepository<MessageEntity, Long> {

    @Query("SELECT m FROM MessageEntity m WHERE m.conversationId = :convId ORDER BY m.createdAt DESC")
    List<MessageEntity> findRecentByConversationId(@Param("convId") String conversationId, Pageable pageable);
}

package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.ConversationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversationJpaRepository extends JpaRepository<ConversationEntity, String> {
}

package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.LeadEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LeadJpaRepository extends JpaRepository<LeadEntity, Long> {
}

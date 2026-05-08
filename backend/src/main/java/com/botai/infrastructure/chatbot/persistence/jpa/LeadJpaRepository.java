package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.LeadEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LeadJpaRepository extends JpaRepository<LeadEntity, Long> {
}

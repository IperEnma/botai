package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.BotEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BotJpaRepository extends JpaRepository<BotEntity, Long> {
    
    List<BotEntity> findByUserId(String userId);
    
    Optional<BotEntity> findByTenantId(String tenantId);

    Optional<BotEntity> findFirstByWhatsappPhoneNumberId(String whatsappPhoneNumberId);
}

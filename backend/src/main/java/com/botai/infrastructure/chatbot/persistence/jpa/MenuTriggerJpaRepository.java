package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.MenuTriggerEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MenuTriggerJpaRepository extends JpaRepository<MenuTriggerEntity, Long> {

    List<MenuTriggerEntity> findByTenantId(String tenantId);
}

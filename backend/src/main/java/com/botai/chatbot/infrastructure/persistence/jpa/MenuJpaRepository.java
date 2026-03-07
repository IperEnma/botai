package com.botai.chatbot.infrastructure.persistence.jpa;

import com.botai.chatbot.infrastructure.persistence.entity.MenuEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MenuJpaRepository extends JpaRepository<MenuEntity, Long> {

    Optional<MenuEntity> findByTenantIdAndMenuKeyAndActiveTrue(String tenantId, String menuKey);
    
    java.util.List<MenuEntity> findByTenantIdAndActiveTrue(String tenantId);
}

package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.BotLessonEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BotLessonJpaRepository extends JpaRepository<BotLessonEntity, Long> {

    List<BotLessonEntity> findByTenantIdAndActiveTrueOrderByNameAsc(String tenantId);
}

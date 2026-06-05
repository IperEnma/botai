package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.BotLesson;
import com.botai.domain.chatbot.repository.BotLessonRepository;
import com.botai.infrastructure.chatbot.persistence.entity.BotLessonEntity;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.stream.Collectors;

@Repository
public class JpaBotLessonRepository implements BotLessonRepository {

    private final BotLessonJpaRepository jpaRepository;

    public JpaBotLessonRepository(BotLessonJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public List<BotLesson> findAllActiveByTenantId(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            return List.of();
        }
        return jpaRepository.findByTenantIdAndActiveTrueOrderByNameAsc(tenantId).stream()
            .map(this::toDomain)
            .collect(Collectors.toList());
    }

    private BotLesson toDomain(BotLessonEntity e) {
        return new BotLesson(e.getName(), e.getTriggerKeywords(), e.getContent());
    }
}

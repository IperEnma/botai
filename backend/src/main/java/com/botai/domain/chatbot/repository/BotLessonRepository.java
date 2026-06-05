package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.BotLesson;

import java.util.List;

public interface BotLessonRepository {

    List<BotLesson> findAllActiveByTenantId(String tenantId);
}

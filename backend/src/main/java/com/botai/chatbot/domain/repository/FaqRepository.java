package com.botai.chatbot.domain.repository;

import com.botai.chatbot.domain.model.FaqEntry;

import java.util.List;

/**
 * Port for FAQ data. Implementation in infrastructure (JPA).
 */
public interface FaqRepository {

    List<FaqEntry> findAllActive();

    List<FaqEntry> findByIntent(String intent);
}

package com.botai.domain.chatbot.repository;

import com.botai.domain.chatbot.model.FaqEntry;

import java.util.List;

/**
 * Port for FAQ data. Implementation in infrastructure (JPA).
 */
public interface FaqRepository {

    List<FaqEntry> findAllActive();

    List<FaqEntry> findByIntent(String intent);
}

package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.domain.chatbot.model.FaqEntry;
import com.botai.domain.chatbot.model.FaqResponseMode;
import com.botai.domain.chatbot.repository.FaqRepository;
import com.botai.infrastructure.chatbot.persistence.entity.FaqEntity;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.stream.Collectors;

@Repository
public class JpaFaqRepository implements FaqRepository {

    private final FaqJpaRepository jpaRepository;

    public JpaFaqRepository(FaqJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public List<FaqEntry> findAllActive() {
        return jpaRepository.findByActiveTrue().stream()
            .map(this::toEntry)
            .collect(Collectors.toList());
    }

    @Override
    public List<FaqEntry> findByIntent(String intent) {
        return jpaRepository.findByIntentAndActiveTrue(intent).stream()
            .map(this::toEntry)
            .collect(Collectors.toList());
    }

    private FaqEntry toEntry(FaqEntity e) {
        return new FaqEntry(
            e.getIntent(),
            e.getKeywords(),
            e.getResponse(),
            e.isUseRegex(),
            FaqResponseMode.fromDb(e.getResponseMode()));
    }
}

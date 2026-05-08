package com.botai.infrastructure.chatbot.persistence.jpa;

import com.botai.infrastructure.chatbot.persistence.entity.FaqEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FaqJpaRepository extends JpaRepository<FaqEntity, Long> {

    List<FaqEntity> findByActiveTrue();

    List<FaqEntity> findByIntentAndActiveTrue(String intent);
}
